---
title: macOS
---

# Installing Forem on macOS

## Installing prerequisites

### Ruby

1. **Note:** MacOS ships with a version of Ruby, needed for various operating
   systems. To avoid causing an issue with your operating system you should use
   a version manager for Ruby.

   If you don't already have a Ruby version manager, we highly recommend
   [rbenv](https://github.com/rbenv/rbenv). This will allow you to have
   different versions running on a per project basis. The MacOS system version
   of Ruby will stay intact while giving you the ability to use the version
   needed for this Forem project. Please follow their
   [installation guide](https://github.com/rbenv/rbenv#installation).

2. With the Ruby version manager, install the Ruby version listed on our badge.
   (i.e. with rbenv: `rbenv install $(cat .ruby-version)`)

   **Note:** The repository must be forked and cloned before running the
   `rbenv install $(cat .ruby-version)` command.

### Yarn

Please refer to their [installation guide](https://yarnpkg.com/en/docs/install).

### PostgreSQL

Forem requires PostgreSQL version 11 or higher to run.

The easiest way to get started is to use
[Postgres.app](https://postgresapp.com/). Alternatively, check out the official
[PostgreSQL](https://www.postgresql.org/) site for more installation options.

For additional configuration options, check our
[PostgreSQL setup guide](/installation/postgresql).

### ImageMagick

Forem uses [ImageMagick](https://imagemagick.org/) to manipulate images on
upload.

You can install ImageMagick with `brew install imagemagick`.

### Redis

Forem requires Redis version 6.0 or higher to run.

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

## Installing Forem

1. Fork Forem's repository, e.g. <https://github.com/forem/forem/fork>
2. Clone your forked repository in one of two ways:

   - e.g. with HTTPS: `git clone https://github.com/<your-username>/forem.git`
   - e.g. with SSH: `git clone git@github.com:<your-username>/forem.git`

3. Install bundler with `gem install bundler`
4. Set up your environment variables/secrets

   - Take a look at `.env_sample` to see all the `ENV` variables we use and the
     fake default provided for any missing keys.
   - If you use a remote computer as dev env, you need to set `APP_DOMAIN`
     variable to the remote computer's domain name.
   - The [backend guide](/backend) will show you how to get free API keys for
     additional services that may be required to run certain parts of the app.
   - For any key that you wish to enter/replace, follow the steps below.

     1. Create `.env` by copying from the provided template (i.e. with bash:
        `cp .env_sample .env`). This is a personal file that is ignored in git.
     2. Obtain the development variable and apply the key you wish to
        enter/replace. i.e.:

     ```shell
      export CLOUDINARY_API_KEY="SOME_REAL_SECURE_KEY_HERE"
      export CLOUDINARY_API_SECRET="ANOTHER_REAL_SECURE_KEY_HERE"
      export CLOUDINARY_CLOUD_NAME="A_CLOUDINARY_NAME"
     ```

   - You do not need "real" keys for basic development. Some features require
     certain keys, so you may be able to add them as you go.

5. Run `bin/setup`

### Possible error messages

**Error:** `rbenv install hangs at ruby-build: using readline from homebrew`

**_Solution:_**
[Stackoverflow answer](https://stackoverflow.com/questions/63599818/rbenv-install-hangs-at-ruby-build-using-readline-from-homebrew)
`RUBY_CONFIGURE_OPTS=--with-readline-dir="$(brew --prefix readline)" rbenv install 2.0.0`

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
