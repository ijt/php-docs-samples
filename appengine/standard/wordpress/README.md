# A script to set up WordPress on the php72 Runtime on App Engine Standard

This script creates a WordPress project for the
[App Engine standard environment][appengine-standard].

## Prerequisites

* Make sure you have a billing account at [console.cloud.google.com/billing][billing].
* Open a terminal with [bash][bash] if your system has one. If not, open the [GCP Cloud Shell][cloudshell].
* Install [gcloud][gcloud].

## Installation

### Step 1: Command line

Run the following command if you're reading this on the web and haven't already
downloaded the script:
```sh
$ curl -L https://goo.gl/UbhdA7 >make-wordpress-app
```

Choose `PROJECT` as the name you want your new project to have and `DB_TIER` as
your selection from https://cloud.google.com/sql/pricing (try `db-f1-micro` to
test it out). Then run this command to create a new project containing your
WordPress app on App Engine.
```sh
$ bash make-wordpress-app <PROJECT> <DB_TIER>
```
For example, `bash make-wordpress-app wordpress-$RANDOM$RANDOM db-f1-micro`.

The script will ask you to choose a billing account if you have more than one.
Then it will run for around 30 minutes setting up the Cloud SQL instance and
app.

### Step 2: Browser

In your browser, visit the link printed out at the end of Step 1 and fill out
the admin account setup form.

Once that is done, log into the admin interface and go to `Plugins | Installed
Plugins` on the menu on the left. In the Plugins page that appears, click
`Activate` for the `WP-Stateless` plugin. Now your uploaded media will be stored on
GCS and will be visible on your WordPress site.

Enjoy your WordPress installation!

[appengine-standard]: https://cloud.google.com/appengine/docs/standard
[billing]: https://console.cloud.google.com/billing
[gcloud]: https://cloud.google.com/sdk/downloads
[wsl]: https://docs.microsoft.com/en-us/windows/wsl/install-win10
[bash]: https://www.gnu.org/software/bash/
[cloudshell]: https://cloud.google.com/shell/docs/quickstart
