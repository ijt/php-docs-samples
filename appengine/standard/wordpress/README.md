# A script to set up WordPress on App Engine Standard

The script allows you to create a WordPress project for the
[App Engine standard environment][appengine-standard].

## Prerequisites

* Make sure you have a billing account at [console.cloud.google.com/billing][billing].
* Install [gcloud][gcloud].

## Installation

```sh
./make-wordpress-app.bash PROJECT DB_TIER
```
where PROJECT is the name you want your new project to have and DB\_TIER is
your selection from https://cloud.google.com/sql/pricing.

Enjoy your WordPress installation!

[appengine-standard]: https://cloud.google.com/appengine/docs/standard
[billing]: https://console.cloud.google.com/billing
[gcloud]: https://cloud.google.com/sdk/downloads
