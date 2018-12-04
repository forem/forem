## Installing prerequisites

These prerequisites assume you're working on a Linux-based operating system but have been tested on Ubuntu 18.04.

### Ruby

1. If you don't already have a Ruby version manager, we highly recommend [rbenv](https://github.com/rbenv/rbenv). Please follow their [installation guide](https://github.com/rbenv/rbenv#installation).
2. With the Ruby version manager, install the Ruby version listed on our badge. (ie with rbenv: `rbenv install 2.5.3`)

For very detailed rbenv installation directions on several distros, please visit [DigitalOcean's guide](https://www.digitalocean.com/community/tutorials/how-to-install-ruby-on-rails-with-rbenv-on-ubuntu-18-04).

### Yarn

There are two ways to install Yarn.

- Yarn's official [installation guide](https://yarnpkg.com/en/docs/install#debian-stable).
- [DigitalOcean's detailed tutorial](https://www.digitalocean.com/community/tutorials/how-to-install-node-js-on-ubuntu-18-04) describes how to install [Node version Manager](https://github.com/creationix/nvm). By installing NVM you can select a Node version (we recommend either LTS or current), the guide will also explain how to install NPM. This way you'll have Node, NPM, and then you can run `npm install -g yarn` to install Yarn.

### PostgreSQL

1.  run `sudo apt update && sudo apt install postgresql postgresql-contrib libpq-dev`.
2.  To test the installation you can run `sudo -u postgres psql` which should open a PostgreSQL prompt. Exit the prompt by running `\q` then run `sudo -u postgres createuser -s $YOUR_USERNAME` where \$YOUR_USERNAME is the username you are currently logged in as. Lastly, at least on Debian based systems, in the codebase under /config/database.yml you'll want to comment out the `host: localhost` to configure the database to use Unix domain sockets as outlined [here](https://stackoverflow.com/questions/23375740/pgconnectionbad-fe-sendauth-no-password-supplied).

There are more than one way to setup Postgres. For additional configuration, check out our [postgres doc](/additional-postgres-setup) or the official [PostgreSQL](https://www.postgresql.org/) site for more information.

## Installing Dev.to

1.  Fork dev.to repository, ie. https://github.com/thepracticaldev/dev.to/fork
2.  Clone your forked repository, ie. `git clone https://github.com/<your-username>/dev.to.git`
3.  Install bundler with `gem install bundler`
4.  Install foreman gem with `gem install foreman`
5.  Install our ruby dependencies with `bundle install`
6.  Install our frontend dependencies with `bin/yarn`
7.  Setup your database

- Create `config/database.yml` by copying from the provided template (i.e. `cp config/database.yml.sample config/database.yml`)
- Update the `config/database.yml` file if needed.

8.  Set up your environment variables/secrets

- Take a look at `Envfile`. This file lists all the `ENV` variables we use and provides a fake default for any missing keys. You'll need to get your own free [Algolia credentials](http://docs.dev.to/get-api-keys-dev-env/#algolia) to get your development environment running.
- This [guide](http://docs.dev.to/get-api-keys-dev-env/) will show you how to get free API keys for additional services that may be required to run certain parts of the app.
- For any key that you wish to enter/replace:

9.  Create `config/application.yml` by copying from the provided template (ie. with bash: `cp config/sample_application.yml config/application.yml`). This is a personal file that is ignored in git.
10. Obtain the development variable and apply the key you wish to enter/replace. ie:


    ```
    GITHUB_KEY: "SOME_REAL_SECURE_KEY_HERE"
    GITHUB_SECRET: "ANOTHER_REAL_SECURE_KEY_HERE"
    ```

- If you are missing `ENV` variables on bootup, `envied` gem will alert you with messages similar to `'error_on_missing_variables!': The following environment variables should be set: A_MISSING_KEY.`.
- You do not need "real" keys for basic development. Some features require certain keys, so you may be able to add them as you go.

11. Run `bin/setup`
