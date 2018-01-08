# Setting Up WordPress on the php72 Runtime on App Engine Standard

1. Open a terminal with [bash][bash] if your system has one. If not, open the [GCP Cloud Shell][cloudshell].
2. [Install gcloud][install-gcloud] if it isn't already installed.
3. Choose an existing GCP project (whose id is called `$proj` below) or [create a new project][create-project].
4. [Enable billing][enable-billing] for `$proj`.

5. **Clone the repo** and cd into this directory:
```sh
$ git clone https://github.com/GoogleCloudPlatform/php-docs-samples
$ cd php-docs-samples/appengine/standard/wordpress
```

6. Create a Cloud SQL instance and db:
```sh
db_tier=db-f1-micro  # See https://cloud.google.com/sql/pricing for more choices
db_instance=wordpress
db_name=wordpress
db_pass=$(head -c20 </dev/urandom | xxd -p)
proj=[ID OF YOUR PROJECT]
gcloud config set project $proj
./set-up-mysql $db_tier $db_instance $db_name $db_pass
```

7. Create and deploy a WordPress app on App Engine with the php72 runtime:
```sh
d=$(pwd)
cd [DIR WHERE YOU WANT TO CREATE YOUR APP]
$d/update-wordpress
cd wordpress
$d/gen-wp-config >wp-config.php

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
gcloud sql instances patch $db_instance --authorized-gae-apps $proj
gcloud app deploy
```

8. Configure WordPress from the browser.
Once the app is deployed, open it in your browser and fill out the admin
account setup form that appears.

9. Log into the admin interface and go to `Plugins | Installed
Plugins` on the menu on the left. In the Plugins page that appears, click
`Activate` for the `WP-Stateless` plugin. Now your uploaded media will be stored on
GCS and will be visible on your WordPress site.

## Updating
When new versions of WordPress become available, you can update your app to use them
by running these commands:
```sh
d=$(pwd)
cd [DIR WHERE YOU CREATED YOUR APP]
$d/update-wordpress
cd wordpress
gcloud app deploy
```
Updating from within the WordPress admin console will not work because the php72
runtime has a mostly read-only file system.

Enjoy your WordPress installation!

[bash]: https://www.gnu.org/software/bash/
[cloudshell]: https://cloud.google.com/shell/docs/quickstart
[create-project]: https://cloud.google.com/resource-manager/docs/creating-managing-projects
[enable-billing]: https://cloud.google.com/billing/docs/how-to/modify-project
[install-gcloud]: https://cloud.google.com/sdk/downloads
[wsl]: https://docs.microsoft.com/en-us/windows/wsl/install-win10
