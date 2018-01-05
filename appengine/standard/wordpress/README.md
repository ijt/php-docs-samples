# A script to set up WordPress on App Engine Standard

This script creates a WordPress project for the
[App Engine standard environment][appengine-standard].

## Prerequisites

* Make sure you have a billing account at [console.cloud.google.com/billing][billing].
* Open a terminal with [bash][bash] if your system has one. If not, open the [GCP Cloud Shell][cloudshell].
* Install [gcloud][gcloud].

## Installation

### Step 1: Command line

```sh
$ wget https://raw.githubusercontent.com/ijt/php-docs-samples/add-wordpress-app-maker-script-for-php72/appengine/standard/wordpress/make-wordpress-app
$ bash make-wordpress-app PROJECT DB_TIER
```
where PROJECT is the name you want your new project to have and DB\_TIER is your selection from https://cloud.google.com/sql/pricing (try db-f1-micro to test it out).

The script will ask you to choose a billing account if you have more than one. Then it will run for around 10 minutes setting up the Cloud SQL instance and app.

### Step 2: Browser

In your browser, visit the link printed out at the end of Step 1 and fill out the admin account setup form.

Once that is done, log into the admin interface and go to Plugins | Installed Plugins on the menu on the left. In the Plugins page that appears, click Activate for the WP-Stateless plugin. Now your uploaded media will be stored on GCS and will be visible on your WordPress site.

Enjoy your WordPress installation!

[appengine-standard]: https://cloud.google.com/appengine/docs/standard
[billing]: https://console.cloud.google.com/billing
[gcloud]: https://cloud.google.com/sdk/downloads
[wsl]: https://docs.microsoft.com/en-us/windows/wsl/install-win10
[bash]: https://www.gnu.org/software/bash/
[cloudshell]: https://cloud.google.com/shell/docs/quickstart
