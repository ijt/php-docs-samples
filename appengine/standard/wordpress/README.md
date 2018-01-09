# Setting Up WordPress on the php72 Runtime on App Engine Standard

1. Open a terminal with [bash][bash] if your system has one. If not, open the [GCP Cloud Shell][cloudshell].

2. Clone the repo and store this subdirectory's path in `$aewp` (App Engine
   WordPress) for later use:
```sh
git clone https://github.com/ijt/php-docs-samples
aewp=$(pwd)/php-docs-samples/appengine/standard/wordpress
```

3. [Install gcloud][install-gcloud] if it isn't already installed.
4. Choose an existing GCP project or create a new project:
```sh
proj=[ID FOR YOUR NEW PROJECT]
gcloud projects create ${proj?}
gcloud config set project ${proj?}
```
5. List your billing accounts:
```sh
gcloud alpha billing accounts list
```
6. Enable billing for your project:
```sh
account=[ACCOUNT ID CHOSEN FROM THE LIST]
gcloud alpha billing projects link --billing-account=${account?} ${proj?}
```

7. Create the Cloud SQL instance and db:
```sh
proj=[ID OF YOUR PROJECT]  # if working in an existing project
db_tier=db-f1-micro  # See https://cloud.google.com/sql/pricing for more choices
db_instance=wordpress
db_name=wordpress
db_pass=$(head -c8 </dev/urandom | xxd -p)

gcloud sql instances create ${db_instance?} --tier=${db_tier?} --region=us-central1
gcloud sql users set-password root % --instance ${db_instance?} --password ${db_pass?}
gcloud sql databases create ${db_name?} --instance=${db_instance?}
```

8. Create and deploy the App Engine app:
```sh
app=[DIR WHERE YOU WANT TO CREATE YOUR APP]
mkdir -p ${app?}
cd ${app?}
ln -s ${aewp?} aewp
aewp/update-wordpress
cd wordpress
aewp/gen-wp-config ${db_instance?} ${db_name?} ${db_pass?} >wp-config.php
cp aewp/app.yaml .
echo 'zend_extension=opcache.so' >php.ini

# At the time of this writing, us-central is the only region available for
# php72.
gcloud app create --region=us-central
gcloud sql instances patch ${db_instance?} --authorized-gae-apps ${proj?}
gcloud app deploy
```

9. Open the URL printed out by `gcloud app deploy` for your app and fill out
the admin account setup form that appears.

10. A login page will appear for the admin interface for your WordPress app.
Log into the admin interface.

11. Click `Plugins | Installed Plugins` on the menu on the left.  In the
Plugins page that appears, click `Activate` for the `WP-Stateless` plugin.
Now your uploaded media will be stored on GCS and will be visible on your
WordPress site.

Enjoy your WordPress app!

## Updating
When a new version of WordPress becomes available, you can update your app to use it
like this:
```sh
cd ${app?}
aewp/update-wordpress
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
