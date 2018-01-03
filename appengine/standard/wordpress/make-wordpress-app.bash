#!/bin/bash

project=$1
account=$2
db_tier=$3

function die() {
  echo "$@"
  exit 1
}

if [[ -z "$project" || -z "$account" || -z "$db_tier" ]]; then
  die "Usage: $0 PROJECT ACCOUNT DB_TIER

PROJECT is the name of the GCP project to create, and the name of a directory
for its source.

ACCOUNT is the billing account to use for this project. It can be gotten by
running  gcloud alpha billing accounts list  and selecting from the ID column.

DB_TIER is the tier of the Cloud SQL instance to create, for example
db-g1-small for testing or db-n1-standard-1 for production. See
https://cloud.google.com/sql/pricing for a list of db tiers and their prices.
"
fi

set -u
set -o pipefail

db_instance=instance
db_name=wordpress
db_pass=$(head -c8 </dev/urandom | xxd -p)

log=$(mktemp)
echo "Logging to $log."

echo "Fetching and unpacking the latest version of WordPress into ./$project."
curl --silent https://wordpress.org/latest.zip >wordpress.zip \
  || die "Failed to fetch latest version of WordPress."
unzip wordpress.zip &>$log || die "Failed to unzip wordpress.zip: $(cat $log)"
mv wordpress $project || die "Failed to rename wordpress directory to $project"
cd $project || die "Failed to cd into $project."

echo "Setting up GCP project $project with billing enabled."
gcloud projects create $project &>$log \
  || die "Failed to create project $project: $(cat $log)"
gcloud config set project $project &>$log \
  || die "Failed to make $project current: $(cat $log)"
gcloud alpha billing projects link --billing-account=$account $project \
  &>$log || die "Failed to enable billing: $(cat $log)"

echo "Setting up a Cloud SQL instance."
gcloud sql instances create $db_instance --tier=$db_tier --region=us-central1 \
  &>$log || die "Failed to create Cloud SQL instance: $(cat $log)"
gcloud sql users set-password root % --instance $db_instance --password \
  $db_pass &>$log \
  || die "Failed to set db root password to $db_pass: $(cat $log)"
gcloud sql databases create $db_name --instance=$db_instance \
  &>$log || die "Failed to create database $db_name: $(cat $log)"

echo "Configuring WordPress."
cp wp-config-sample.php wp-config.php || die "Failed to create wp-config.php."
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
gcloud app create --region=us-central &>$log \
  || die "Failed to create GAE app: $(cat $log)"
gcloud sql instances patch $db_instance --authorized-gae-apps $project &>$log \
  || die "Failed to authorize GAE app to connect to db: $(cat $log)"
echo y | gcloud app deploy &>$log
if [[ $? != 0 ]]; then die "Failed to deploy GAE app: $(cat $log)"; fi

url=$(grep -o "http[s:/]*$project.*\.com" $log | head -n 1)
if [[ $? != 0 ]]; then die "Failed to find app url in $log."; fi
echo "Your new WordPress app is at $url."