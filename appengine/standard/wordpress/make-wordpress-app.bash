#!/bin/bash

project=$1
db_tier=$2

function die() {
  echo "$@"
  exit 1
}

if [[ -z "$project" || -z "$db_tier" ]]; then
  die "Usage: $0 PROJECT DB_TIER

PROJECT is the name of the GCP project to create, and the name of a directory
for its source.

DB_TIER is the tier of the Cloud SQL instance to create, for example
db-f1-micro for testing or db-n1-standard-1 for production. See
https://cloud.google.com/sql/pricing for a list of db tiers and their prices.
"
fi

set -u
set -o pipefail

db_instance=instance
db_name=wordpress
db_pass=$(head -c8 </dev/urandom | xxd -p)

dir=$(mktemp -d /tmp/wp-XXXX)
log=$dir/log
cd $dir
echo "Working in $dir, logging to $log. To watch progress use 'tail -f $log'."

# Figure out which billing account to use.
IFS=$'\n';
gcloud components update &>$log || die "Failed to update gcloud: $(cat $log)"
echo y | gcloud components install alpha &>$log
if [[ $? != 0 ]]; then die "Failed to install gcloud alpha component: $log"; fi
accounts=( $(gcloud alpha billing accounts list \
            | perl -pe 's/(True|False)$//' \
            | awk '{if(NR>1) print}') )
case ${#accounts[@]} in
0)
  die "No billing accounts found. Please create one."
  ;;
1)
  account=${accounts[0]}
  ;;
*)
  PS3='Please choose your billing account: '
  select opt in "${accounts[@]}"; do
    account=$(echo $opt | awk '{print $1}')
    break
  done
  ;;
esac
echo "Using billing account $account."

echo "Fetching and unpacking the latest version of WordPress into ./$project."
curl --silent https://wordpress.org/latest.zip >wordpress.zip \
  || die "Failed to fetch latest version of WordPress."
unzip wordpress.zip >$log || die "Failed to unzip wordpress.zip: $(tail $log)"
mv wordpress $project || die "Failed to rename wordpress directory to $project"
curl --silent https://downloads.wordpress.org/plugin/wp-stateless.2.1.1.zip >wp-stateless.zip \
  || die "Failed to fetch wp-stateless."
unzip wp-stateless.zip >$log || die "Failed to unzip wp-stateless.zip: $(tail $log)"
mv wp-stateless $project/wp-content/plugins &>$log \
  || die "Failed to move wp-stateless plugin into place: $(cat $log)"
cd $project || die "Failed to cd into $project."

echo "Setting up GCP project $project with billing enabled."
gcloud projects create $project &>$log \
  || die "Failed to create project $project: $(cat $log)"
gcloud config set project $project &>$log \
  || die "Failed to make $project current: $(cat $log)"
gcloud alpha billing projects link --billing-account=$account $project \
  &>$log || die "Failed to enable billing: $(cat $log)"

echo "Setting up a Cloud SQL instance."
# This next command sometimes times out for db-f1-micro, giving the impression
# that it has failed even when it hasn't. That's why the exit status is ignored
# here and a separate check is done on the next line.
gcloud sql instances create $db_instance --tier=$db_tier --region=us-central1 \
  &>$log
if [[ $? != 0 ]]; then
  if ! grep "continue waiting" $log; then
    die "Failed to create instance: $(cat $log)"
  fi
  echo "Cloud SQL instance creation is taking longer than expected."
  if [[ "$db_tier" == "db-f1-micro" ]]; then
    echo "This often happens for db-f1-micro instances."
  fi
  echo "Waiting longer."
  op=$(gcloud beta sql operations list --instance=instance 2>$log \
      | sed 1d | awk '{print $1}')
  if [[ $? != 0 ]]; then die "Failed to get instance creation op id: $(cat $log)"; fi
  gcloud beta sql operations wait $op &>$log \
    || die "Failed to wait for gcloud sql operation: $(cat $log)"
fi
gcloud sql users set-password root % --instance $db_instance --password \
  $db_pass &>$log \
  || die "Failed to set db root password to $db_pass: $(cat $log)"
gcloud sql databases create $db_name --instance=$db_instance \
  &>$log || die "Failed to create database $db_name: $(cat $log)"

echo "Configuring WordPress."
echo "  Making WordPress use /tmp for uploads because /tmp is writable but \
the app directory tree is not."
cp wp-config-sample.php wp-config.php || die "Failed to create wp-config.php."
sed -i.bak 's#<?php#<?php\n\ndefine("UPLOADS", "/tmp");\n\n#' wp-config.php \
  2>$log || die "Failed to define UPLOADS in wp-config.php: $(cat $log)"
# TODO(ijt): See if we can change WordPress upstream to respect absolute
# UPLOADS dirs such as /tmp.
sed -i.bak 's/\<ABSPATH \. UPLOADS\>/UPLOADS/g' $(find . -name \*.php) 2>$log \
  || die "Failed to strip ABSPATH prefix from UPLOADS in WordPress sources: \
    $(cat $log)"
echo "  Configuring db connection."
sed -i.bak "s/database_name_here/$db_name/" wp-config.php \
  || die "Failed to set db name in wp-config.php."
sed -i.bak 's/username_here/root/' wp-config.php \
  || die "Failed to set db username to root in wp-config.php."
sed -i.bak "s/password_here/$db_pass/" wp-config.php \
  || die "Failed to set db password in wp-config.php."
db_conn_name=$(gcloud sql instances describe $db_instance \
             | grep connectionName \
             | sed 's/connectionName: //')
db_host=":/cloudsql/$db_conn_name"
sed -i.bak "s#'DB_HOST', 'localhost'#'DB_HOST', '$db_host'#" wp-config.php \
  || die "Failed to set db host in wp-config.php."
rm wp-config.php.bak

echo "Setting up an App Engine app."
echo "\
runtime: php72
instance_class: F4

handlers:
- url: /(.*)
  script: \1" >app.yaml || die "Failed to create app.yaml"
echo "  Creating the app."
gcloud app create --region=us-central &>$log \
  || die "Failed to create GAE app: $(cat $log)"
echo "  Giving the app access to the Cloud SQL instance."
gcloud sql instances patch $db_instance --authorized-gae-apps $project &>$log \
  || die "Failed to authorize GAE app to connect to db: $(cat $log)"
echo "  Deploying the app."
echo y | gcloud app deploy &>$log
if [[ $? != 0 ]]; then die "Failed to deploy GAE app: $(cat $log)"; fi

url=$(grep -o "http[s:/]*$project.*\.com" $log | head -n 1)
if [[ $? != 0 ]]; then die "Failed to find app url in $log."; fi
echo "Your new WordPress app is at $url."
