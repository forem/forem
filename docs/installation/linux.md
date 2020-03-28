---
title: Linux
---

# Installing DEV on Linux

## Installing prerequisites

_These prerequisites assume you're working on a Linux-based operating system,
but they have only been tested on Ubuntu 18.04._

### Ruby

1. If you don't already have a Ruby version manager, we highly recommend
   [rbenv](https://github.com/rbenv/rbenv). Please follow their
   [installation guide](https://github.com/rbenv/rbenv#installation).
1. With the Ruby version manager, install the Ruby version listed on our badge.
   (ie with rbenv: `rbenv install 2.6.5`)

For very detailed rbenv installation directions on several distros, please visit
[DigitalOcean's guide](https://www.digitalocean.com/community/tutorials/how-to-install-ruby-on-rails-with-rbenv-on-ubuntu-18-04).

### Yarn

There are two ways to install Yarn.

- Yarn's official
  [installation guide](https://yarnpkg.com/en/docs/install#debian-stable)
  (recommended).
- [DigitalOcean's detailed tutorial](https://www.digitalocean.com/community/tutorials/how-to-install-node-js-on-ubuntu-18-04)
  describes how to install
  [Node version Manager](https://github.com/creationix/nvm). By installing NVM
  you can select a Node version (we recommend either LTS or current); the guide
  will also explain how to install NPM. This way you'll have Node, NPM, and then
  you can run `npm install -g yarn` to install Yarn.

### PostgreSQL

DEV requires PostgreSQL version 9.5 or higher.

1. Run
   `sudo apt update && sudo apt install postgresql postgresql-contrib libpq-dev`.
1. To test the installation you can run `sudo -u postgres psql` which should
   open a PostgreSQL prompt. Exit the prompt by running `\q` then run
   `sudo -u postgres createuser -s $YOUR_USERNAME` where `$YOUR_USERNAME` is the
   username you are currently logged in as.

There are more than one ways to setup PostgreSQL. For additional configuration,
check out our [PostgreSQL setup guide](/installation/postgresql) or the official
[PostgreSQL](https://www.postgresql.org/) site for further information.

### ImageMagick

DEV uses [ImageMagick](https://imagemagick.org/) to manipulate images on upload.

Please refer to ImageMagick's
[instructions](https://imagemagick.org/script/download.php) on how to install
it.

### Redis

DEV requires Redis version 4.0 or higher.

We recommend following Digital Ocean's extensive
[How To Install and Configure Redis on Ubuntu 16.04](https://www.digitalocean.com/community/tutorials/how-to-install-and-configure-redis-on-ubuntu-16-04)
(available for other Linux distributions as well) to setup Redis.

### Elasticsearch

DEV requires a version of Elasticsearch between 7.1 and 7.5. Version 7.6 is not
supported. We recommend version 7.5.2.

We recommend following
[Elasticsearch's guide for installing on Linux](https://www.elastic.co/guide/en/elasticsearch/reference/7.5/targz.html#install-linux).

Elasticsearch is also available as as
[Debian package](https://www.elastic.co/guide/en/elasticsearch/reference/7.5/deb.html)
or a
[RPM package](https://www.elastic.co/guide/en/elasticsearch/reference/7.5/rpm.html).

NOTE: Make sure to download **the OSS version**, `elasticsearch-oss`.

## Installing DEV

1. Fork DEV's repository, e.g. <https://github.com/thepracticaldev/dev.to/fork>
1. Clone your forked repository, e.g.
   `git clone https://github.com/<your-username>/dev.to.git`
1. Install bundler with `gem install bundler`
1. Set up your environment variables/secrets

   - Take a look at `Envfile`. This file lists all the `ENV` variables we use
     and provides a fake default for any missing keys. You'll need to get your
     own free [Algolia credentials](/backend/algolia) to get your development
     environment running.
   - The [backend guide](/backend) will show you how to get free API keys for
     additional services that may be required to run certain parts of the app.
   - For any key that you wish to enter/replace:

     1. Create `config/application.yml` by copying from the provided template
        (i.e. with bash:
        `cp config/sample_application.yml config/application.yml`). This is a
        personal file that is ignored in git.
     1. Obtain the development variable and apply the key you wish to
        enter/replace. i.e.:

     ```shell
     GITHUB_KEY: "SOME_REAL_SECURE_KEY_HERE"
     GITHUB_SECRET: "ANOTHER_REAL_SECURE_KEY_HERE"
     ```

   - If you are missing `ENV` variables on bootup, the
     [envied](https://rubygems.org/gems/envied) gem will alert you with messages
     similar to
     `'error_on_missing_variables!': The following environment variables should be set: A_MISSING_KEY.`.
   - You do not need "real" keys for basic development. Some features require
     certain keys, so you may be able to add them as you go.

1. Run `bin/setup`

### Possible error messages

While installing, you might run into an error due to the `pg` gem requiring
PostgreSQL libraries. If so, please run `sudo apt-get install libpq-dev` before
retrying.

While installing, you might run into an error due to the `sass-rails` gem
requiring `sassc`, which requires the `g++` compiler. If so, please run
`sudo apt-get install g++` before retrying.

While installing, if you didn't install `node` or `nvm` manually, you might run
into an error due to an older system node version being present, which can cause
issues while `yarn` is installing packages. If so, you'll need to
[install `nvm`](https://github.com/nvm-sh/nvm#installation-and-update) and then
run `nvm install node` to get the most recent node version before retrying.
