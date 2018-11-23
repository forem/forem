## Installing prerequisites

These prerequisites assume you're working on a 64bit Windows 10 operating system machine.

### Installing WSL

Since dev.to codebase is using Ruby on Rails framework, we will need to install Windows Subsystem for Linux. Some dependencies used by the source code triggered errors when installing on Windows, so using WSL allows you to work on the software and not fixing gem incompatibilities.

First, let's enable Windows Subsystem for Linux in your machine. You can do this by opening Control Panel, going to Programs, and then clicking "Turn Windows Features On or Off". Looking for the "Windows Subsystem for Linux" option and check the box next to it. Windows will ask for a reboot.

![Enable WSL on Windows](/wsl-feature.png 'Enable WSL on Windows')

Once you've got this installed and after rebooting, follow [this link](https://www.microsoft.com/store/productId/9N9TNGVNDL3Q) to install Ubuntu 18.04 on Windows.

On your first run, the system will ask for username and password. Take note of both since it will be used for `sudo` commands.

### Ruby on WSL

First, install Ruby language dependencies:

```
sudo apt-get update
sudo apt-get install git-core curl zlib1g-dev build-essential libssl-dev libreadline-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev libcurl4-openssl-dev software-properties-common libffi-dev
```

For installing Ruby, we recommend using [rbenv](https://github.com/rbenv/rbenv)

```
cd
git clone https://github.com/rbenv/rbenv.git ~/.rbenv
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(rbenv init -)"' >> ~/.bashrc
exec $SHELL

git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
echo 'export PATH="$HOME/.rbenv/plugins/ruby-build/bin:$PATH"' >> ~/.bashrc
exec $SHELL

rbenv install 2.5.3
rbenv global 2.5.3
ruby -v
```

### Installing Rails

Since Rails ships with so many dependencies these days, we're going to need to install a Javascript runtime like NodeJS. This lets you use Coffeescript and the Asset Pipeline in Rails which combines and minifies your javascript to provide a faster production environment.

To install NodeJS, we're going to add it using the official repository:

```
curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -
sudo apt-get install -y nodejs
node -v
npm -v
```

If `npm -v` gives `Syntax error: word unexpected (expecting "in")`, restart the terminal and try again.

And now, for rails itself:

```
gem install rails -v 5.1.6
```

Then run `rbenv rehash` to make Rails executable available. Check it out by using `rails -v` command

```
rbenv rehash
rails -v
# Rails 5.1.6
```

### Yarn

The fastest way to install Yarn for WSL would be from Debian package repository. Configure the repository with the following commands:

```
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
```

Then you can simply:

```
sudo apt-get update && sudo apt-get install yarn
```

Make sure that Yarn is installed with `yarn -v`

### PostgreSQL

If you don't have PostgreSQL installed on your Windows system, You can do so here. WSL is able to connect to Windows Postgresql.

Download [PostgreSQL for Windows](https://www.openscg.com/bigsql/postgresql/installers.jsp/) and install it.

Pay attention to the username and password you setup during installation of Postgres as you will use this to configure your Rails applications to login to Postgres later.

## Installing Dev.to

1.  Fork dev.to repository, ie. https://github.com/thepracticaldev/dev.to/fork
2.  Clone your forked repository, ie. `git clone https://github.com/<your-username>/dev.to.git`
3.  Install bundler with `gem install bundler`
4.  Install foreman gem with `gem install foreman`
5.  Run `rbenv rehash` when foreman installation is done.
6.  Install our ruby dependencies with `bundle install`
    While installing, you might run into an error due to the pg gem requiring PostgreSQL libraries. If so, please run `sudo apt-get install libpq-dev` before retrying.
7.  Install our frontend dependencies with `bin/yarn`
8.  Set up your environment variables/secrets

- Take a look at `Envfile`. This file lists all the `ENV` variables we use and provides a fake default for any missing keys. You'll need to get your own free [Algolia credentials](http://docs.dev.to/get-api-keys-dev-env/#algolia) to get your development environment running.
- This [guide](http://docs.dev.to/get-api-keys-dev-env/) will show you how to get free API keys for additional services that may be required to run certain parts of the app.
- For any key that you wish to enter/replace:

10. Create `config/application.yml` by copying from the provided template (ie. with bash: `cp config/sample_application.yml config/application.yml`). This is a personal file that is ignored in git.
11. Obtain the development variable and apply the key you wish to enter/replace. ie:


    ```
    GITHUB_KEY: "SOME_REAL_SECURE_KEY_HERE"
    GITHUB_SECRET: "ANOTHER_REAL_SECURE_KEY_HERE"
    ```

- If you are missing `ENV` variables on bootup, `envied` gem will alert you with messages similar to `'error_on_missing_variables!': The following environment variables should be set: A_MISSING_KEY.`.
- You do not need "real" keys for basic development. Some features require certain keys, so you may be able to add them as you go.

12. Now Configure database.yaml to connect to PostgreSQL run in Windows instead of Ubuntu. Make sure it looks like the following:

    ```
    development:
    <<: *default
    database: PracticalDeveloper_development
    host: localhost
    username: # your Postgres username
    password: # your Postgres password
    ```

    The database username and password also have to be manually added to test database in database.yml
    Another possible way to configure database connection is to setup DATABASE_URL in application.yml as documented [here](https://docs.dev.to/additional-postgres-setup/#configuration)

13. Run `bin/setup`

#### Other Possible Error Messages

1. There is a possibility that you might encounter a _statement timeout_ when seeding the database for the first time. Please comment out the variable `statement_timeout` from database.yml if it happens.

> If you encountered any errors that you subsequently resolved, **please consider updating this section** with your errors and their solutions.
