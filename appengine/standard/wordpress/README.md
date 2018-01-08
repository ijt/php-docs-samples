# Setting Up WordPress on the php72 Runtime on App Engine Standard

1. Open a terminal with [bash][bash] if your system has one. If not, open the [GCP Cloud Shell][cloudshell].

2. **Clone the repo** and cd into this directory:
```sh
git clone https://github.com/ijt/php-docs-samples
cd php-docs-samples/appengine/standard/wordpress
d=$(pwd)
```

3. [Install gcloud][install-gcloud] if it isn't already installed.
4. Choose an existing GCP project or create a new project by running
```sh
proj=[ID FOR YOUR NEW PROJECT]
gcloud projects create ${proj?}
gcloud config set project ${proj?}
```
5. Enable billing for `$proj`. You can see a list of billing accounts by running
```sh
gcloud alpha billing accounts list
```
To enable billing run
```sh
account=[ACCOUNT ID CHOSEN FROM THE LIST]
gcloud alpha billing projects link --billing-account=${account?} ${proj?}
```

6. Create the Cloud SQL instance and db:
```sh
proj=[ID OF YOUR PROJECT]  # if working in an existing project
db_tier=db-f1-micro  # See https://cloud.google.com/sql/pricing for more choices
db_instance=wordpress
db_name=wordpress
db_pass=$(head -c8 </dev/urandom | xxd -p)

gcloud sql instances create $db_instance --tier=$db_tier --region=us-central1
gcloud sql users set-password root % --instance $db_instance --password $db_pass
gcloud sql databases create $db_name --instance=$db_instance
```

7. Create and deploy the App Engine app:
```sh
app=[DIR WHERE YOU WANT TO CREATE YOUR APP]
mkdir -p ${app?}
cd ${app?}
${d?}/update-wordpress
cd wordpress
${d?}/gen-wp-config ${db_instance?} ${db_name?} ${db_pass?} >wp-config.php

echo "\
runtime: php72
instance_class: F2

handlers:
- url: /(.*)
  script: \1
  secure: always" >app.yaml

# At the time of this writing, us-central is the only region available for
# php72.
gcloud app create --region=us-central
gcloud sql instances patch ${db_instance?} --authorized-gae-apps ${proj?}
gcloud app deploy
```

8. Open the URL printed out by `gcloud app deploy` for your app and fill out
the admin account setup form that appears.

9. A login page will appear for the admin interface for your WordPress app.
Log into the admin interface.

10. Click `Plugins | Installed Plugins` on the menu on the left.  In the
Plugins page that appears, click `Activate` for the `WP-Stateless` plugin.
Now your uploaded media will be stored on GCS and will be visible on your
WordPress site.

Enjoy your WordPress app!

## Updating
When a new version of WordPress become available, you can update your app to use it
like this:
```sh
cd ${app?}
${d?}/update-wordpress
cd wordpress
gcloud app deploy
```
Updating from within the WordPress admin console will not work because the php72
runtime has a mostly read-only file system.

[bash]: https://www.gnu.org/software/bash/
[cloudshell]: https://cloud.google.com/shell/docs/quickstart
[create-project]: https://cloud.google.com/resource-manager/docs/creating-managing-projects
[enable-billing]: https://cloud.google.com/billing/docs/how-to/modify-project
[install-gcloud]: https://cloud.google.com/sdk/downloads
[wsl]: https://docs.microsoft.com/en-us/windows/wsl/install-win10
