---
title: macOS
---

# Installing DEV on macOS

## Installing prerequisites

### Ruby

1. If you don't already have a Ruby version manager, we highly recommend [rbenv](https://github.com/rbenv/rbenv). Please follow their [installation guide](https://github.com/rbenv/rbenv#installation).
2. With the Ruby version manager, install the Ruby version listed on our badge. (ie with rbenv: `rbenv install 2.6.3`)

### Yarn

Please refer to their [installation guide](https://yarnpkg.com/en/docs/install).

### PostgreSQL

DEV requires PostgreSQL version 9.4 or higher. The easiest way to get started is to use [Postgres.app](https://postgresapp.com/). Alternatively, check out the official [PostgreSQL](https://www.postgresql.org/) site for more installation options.

For additional configuration options, check our [PostgreSQL setup guide](/installation/postgresql).

## Installing DEV

1. Fork DEV's repository, eg. <https://github.com/thepracticaldev/dev.to/fork>
1. Clone your forked repository, eg. `git clone https://github.com/<your-username>/dev.to.git`
1. Install bundler with `gem install bundler`
1. Set up your environment variables/secrets

   - Take a look at `Envfile`. This file lists all the `ENV` variables we use and provides a fake default for any missing keys. You'll need to get your own free [Algolia credentials](/backend/algolia) to get your development environment running.
   - The [backend guide](/backend) will show you how to get free API keys for additional services that may be required to run certain parts of the app.
   - For any key that you wish to enter/replace:

     1. Create `config/application.yml` by copying from the provided template (ie. with bash: `cp config/sample_application.yml config/application.yml`). This is a personal file that is ignored in git.
     1. Obtain the development variable and apply the key you wish to enter/replace. ie:

     ```shell
     GITHUB_KEY: "SOME_REAL_SECURE_KEY_HERE"
     GITHUB_SECRET: "ANOTHER_REAL_SECURE_KEY_HERE"
     ```

   - If you are missing `ENV` variables on bootup, the [envied](https://rubygems.org/gems/envied) gem will alert you with messages similar to `'error_on_missing_variables!': The following environment variables should be set: A_MISSING_KEY.`.
   - You do not need "real" keys for basic development. Some features require certain keys, so you may be able to add them as you go.

1. Run `bin/setup`

### Possible error messages

**Error:** `rbenv: version '<version number>' is not installed (set by /Path/To/Local/Repository/.ruby-version)`

**_Solution:_** Run the command `rbenv install <version number>`

---

**Error:** `ruby-build: definition not found: <version number>` when `rbenv` was installed via `brew`.

```shell
ruby-build: definition not found: <version number>

See all available versions with `rbenv install --list`.
If the version you need is missing, try upgrading ruby-build:
```

**_Solution:_**
Run the following to update `ruby-build`, `brew update && brew upgrade ruby-build`. After that, rerun `rbenv install <version number>` and that version will get installed.

---

**Error:**

```shell
== Preparing database ==
    Sorry, you can't use byebug without Readline. To solve this, you need to
    rebuild Ruby with Readline support. If using Ubuntu, try `sudo apt-get
    install libreadline-dev` and then reinstall your Ruby.
rails aborted!
LoadError: dlopen(/Users/<username>/.rbenv/versions/2.6.3/lib/ruby/2.6.0/x86_64-darwin18/readline.bundle, 9): Library not loaded: /usr/local/opt/readline/lib/libreadline.<some version number>.dylib
```

**_Solution:_** Run `ln -s /usr/local/opt/readline/lib/libreadline.dylib /usr/local/opt/readline/lib/libreadline.<some version number>.dylib` from the command line then run `bin/setup` again. You may have a different version or libreadline, so replace `<some version number>` with the version that errored.

---

**Error:**

```shell
PG::Error: ERROR:  invalid value for parameter "TimeZone": "UTC"
: SET time zone 'UTC'
```

**_Solution:_** Restart your Postgres.app, or, if you installed PostgreSQL with Homebrew, restart with:

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

**_Solution:_** You may encounter this when installing PostgreSQL with the Postgres.app. Try restarting the app and reinitializing the database. If that doesn't work, install PostgreSQL with Homebrew instead: `brew install postgresql`

---

> If you encountered any errors that you subsequently resolved, **please consider updating this section** with your errors and their solutions.
