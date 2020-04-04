---
title: macOS
---

# Installing DEV on macOS

## Installing prerequisites

### Ruby

1. If you don't already have a Ruby version manager, we highly recommend
   [rbenv](https://github.com/rbenv/rbenv). Please follow their
   [installation guide](https://github.com/rbenv/rbenv#installation).
2. With the Ruby version manager, install the Ruby version listed on our badge.
   (i.e. with rbenv: `rbenv install 2.7.0`)

### Yarn

Please refer to their [installation guide](https://yarnpkg.com/en/docs/install).

### PostgreSQL

DEV requires PostgreSQL version 9.5 or higher.

The easiest way to get started is to use
[Postgres.app](https://postgresapp.com/). Alternatively, check out the official
[PostgreSQL](https://www.postgresql.org/) site for more installation options.

For additional configuration options, check our
[PostgreSQL setup guide](/installation/postgresql).

### ImageMagick

DEV uses [ImageMagick](https://imagemagick.org/) to manipulate images on upload.

You can install ImageMagick with `brew install imagemagick`.

### Redis

DEV requires Redis version 4.0 or higher.

We recommend using [Homebrew](https://brew.sh):

```shell
brew install redis
```

you can follow the post installation instructions, we recommend using
`brew services` to start Redis in the background:

```shell
brew services start redis
```

You can test if it's up and running by issuing the following command:

```shell
redis-cli ping
```

### Elasticsearch

DEV requires a version of Elasticsearch between 7.1 and 7.5. Version 7.6 is not
supported. We recommend version 7.5.2.

You have the option of installing Elasticsearch with Homebrew or through an
archive. We recommend installing from archive on Mac.

### Installing Elasticsearch from the archive

The following directions were
[taken from the Elasticsearch docs themselves](https://www.elastic.co/guide/en/elasticsearch/reference/7.5/targz.html#install-macos),
so check those out if you run into any issues or want further information. Make
sure to download **the OSS version** of Elasticsearch, `elasticsearch-oss`.

Please note that you will need `wget` in order to proceed with this installation
(`brew install wget`).

```shell
wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-oss-7.5.2-darwin-x86_64.tar.gz
wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-oss-7.5.2-darwin-x86_64.tar.gz.sha512
shasum -a 512 -c elasticsearch-oss-7.5.2-darwin-x86_64.tar.gz.sha512
tar -xzf elasticsearch-oss-7.5.2-darwin-x86_64.tar.gz
```

To start elasticsearch, make sure you are in the correct directory:

```shell
cd elasticsearch-7.5.2
```

You can then start it by running:

```shell
./bin/elasticsearch
```

To start elasticsearch as a daemonized process:

```shell
./bin/elasticsearch -d
```

### Installing Elasticsearch with Homebrew

As the default version of the Homebrew formula points to Elasticsearch 7.6, we
need to retrieve the correct revision of the formula to make sure we install the
latest supported version: 7.5.2.

```shell
brew tap elastic/tap
brew install https://raw.githubusercontent.com/elastic/homebrew-tap/bed8bc6b03213c2c1a7df6e4b9f928e7082fae46/Formula/elasticsearch-oss.rb
brew pin elasticsearch-oss
```

After installation you can manually test if the Elasticsearch server starts by
issuing the command `elasticsearch` in the shell. You can then start the server
as a service with `brew services start elasticsearch-oss`.

You can find further info on your local Elasticsearch installation by typing
`brew info elastic/tap/elasticsearch-oss`.

#### Troubleshooting startup issues

Two possible startup issues you might encounter:

- `java.nio.file.FileSystemLoopException`:

```text
Exception in thread "main" org.elasticsearch.bootstrap.BootstrapException: java.nio.file.FileSystemLoopException: /usr/local/etc/elasticsearch/elasticsearch
Likely root cause: java.nio.file.FileSystemLoopException: /usr/local/etc/elasticsearch/elasticsearch
```

This happens because the installation of Elasticsearch might have a recursive
link in the configuration directory causing the infinite loop:

```shell
> ll /usr/local/etc/elasticsearch
elasticsearch -> /usr/local/etc/elasticsearch
```

By manually removing the link with
`rm -i /usr/local/etc/elasticsearch/elasticsearch` the issue should be fixed.

- `java.lang.IllegalStateException`:

```text
java.lang.IllegalStateException: Could not load plugin descriptor for plugin directory [plugins]
Likely root cause: java.nio.file.NoSuchFileException: /usr/local/Cellar/elasticsearch-oss/7.6.0/libexec/plugins/plugins/plugin-descriptor.properties
```

This happens for a similar reason as the previous error, the installation might
create a recursive link in the plugins directory.

```shell
> ll /usr/local/var/elasticsearch/plugins
plugins -> /usr/local/var/elasticsearch/plugins
```

By manually removing the link with
`rm -i /usr/local/var/elasticsearch/plugins/plugins` the issue should be fixed.

### Testing if Elasticsearch is running

Once installed and started you can test if it's up and running correctly by
issuing the following command:

```shell
curl http://localhost:9200
```

You should receive in response a JSON document containing some information about
your local Elasticsearch installation, for example:

```json
{
  "name": "hostname",
  "cluster_name": "elasticsearch_...",
  "cluster_uuid": "...",
  "version": {
    "number": "7.5.2",
    "build_flavor": "oss",
    "build_type": "tar",
    "build_hash": "8bec50e1e0ad29dad5653712cf3bb580cd1afcdf",
    "build_date": "2020-01-15T12:11:52.313576Z",
    "build_snapshot": false,
    "lucene_version": "8.3.0",
    "minimum_wire_compatibility_version": "6.8.0",
    "minimum_index_compatibility_version": "6.0.0-beta1"
  },
  "tagline": "You Know, for Search"
}
```

## Installing DEV

1. Fork DEV's repository, e.g. <https://github.com/thepracticaldev/dev.to/fork>
2. Clone your forked repository in one of two ways:

   - e.g. with HTTPS: `git clone https://github.com/<your-username>/dev.to.git`
   - e.g. with SSH: `git clone git@github.com:<your-username>/dev.to.git`

3. Install bundler with `gem install bundler`
4. Set up your environment variables/secrets

   - Take a look at `Envfile` to see all the `ENV` variables we use and the fake
     default provided for any missing keys.
   - The [backend guide](/backend) will show you how to get free API keys for
     additional services that may be required to run certain parts of the app.
   - For any key that you wish to enter/replace, follow the steps below. At a
     minimum, you'll need to get your own free
     [Algolia credentials](/backend/algolia) to get your development environment
     running.

     1. Create `config/application.yml` by copying from the provided template
        (i.e. with bash:
        `cp config/sample_application.yml config/application.yml`). This is a
        personal file that is ignored in git.
     2. Obtain the development variable and apply the key you wish to
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

5. Run `bin/setup`

### Possible error messages

**Error:**
`__NSPlaceholderDate initialize] may have been in progress in another thread when fork() was called`

**_Solution:_** Run the command `export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES`
(or `set -x OBJC_DISABLE_INITIALIZE_FORK_SAFETY YES` in fish shell)

---

**Error:** `User does not have CONNECT privilege.`

**_Solution:_** Complete the steps outlined in the
[PostgreSQL setup guide](/installation/postgresql).

---

**Error:**
`rbenv: version '<version number>' is not installed (set by /Path/To/Local/Repository/.ruby-version)`

**_Solution:_** Run the command `rbenv install <version number>`

---

**Error:** `ruby-build: definition not found: <version number>` when `rbenv` was
installed via `brew`.

```shell
ruby-build: definition not found: <version number>

See all available versions with `rbenv install --list`.
If the version you need is missing, try upgrading ruby-build:
```

**_Solution:_** Run the following to update `ruby-build`,
`brew update && brew upgrade ruby-build`. After that, rerun
`rbenv install <version number>` and that version will get installed.

---

**Error:**

```shell
== Preparing database ==
    Sorry, you can't use byebug without Readline. To solve this, you need to
    rebuild Ruby with Readline support. If using Ubuntu, try `sudo apt-get
    install libreadline-dev` and then reinstall your Ruby.
rails aborted!
LoadError: dlopen(/Users/<username>/.rbenv/versions/2.6.5/lib/ruby/2.6.0/x86_64-darwin18/readline.bundle, 9): Library not loaded: /usr/local/opt/readline/lib/libreadline.<some version number>.dylib
```

**_Solution:_** Run
`ln -s /usr/local/opt/readline/lib/libreadline.dylib /usr/local/opt/readline/lib/libreadline.<some version number>.dylib`
from the command line then run `bin/setup` again. You may have a different
version of libreadline, so replace `<some version number>` with the version that
errored.

---

**Error:**

```shell
PG::Error: ERROR:  invalid value for parameter "TimeZone": "UTC"
: SET time zone 'UTC'
```

**_Solution:_** Restart your Postgres.app, or, if you installed PostgreSQL with
Homebrew, restart with:

```shell
brew services restart postgresql
```

If that doesn't work, reboot your Mac.

---

**Error:**

```shell
ERROR:  Error installing pg:
  ERROR: Failed to build gem native extension.
  [...]
Can't find the 'libpq-fe.h header
*** extconf.rb failed ***
```

**_Solution:_** You may encounter this when installing PostgreSQL with the
Postgres.app. Try restarting the app and reinitializing the database. If that
doesn't work, install PostgreSQL with Homebrew instead:
`brew install postgresql`

---

> If you encountered any errors that you subsequently resolved, **please
> consider updating this section** with your errors and their solutions.
