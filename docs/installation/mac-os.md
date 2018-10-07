## Installing prerequisites

### Ruby

1.  If you don't already a Ruby version manager, we highly recommend [rbenv](https://github.com/rbenv/rbenv). Please follow their [installation guide](https://github.com/rbenv/rbenv#installation).
2.  With the Ruby version manager, install Ruby version listed on our badge. (ie with rbenv: `rbenv install 2.5.1`)

### Yarn

Please refer to their [installation guide](https://yarnpkg.com/en/docs/install).

### PostgreSQL

Dev.to requires PostgreSQL version 9.4 or higher. The easiest way to get started is to use [Postgres.app](https://postgresapp.com/). Alternatively, check out the official [PostgreSQL](https://www.postgresql.org/) site for more granular version.

For additional configuration, [click here](/additional-postgres-setup)

## Installing Dev.to

1.  Fork dev.to repository, ie. https://github.com/thepracticaldev/dev.to/fork
2.  Clone your forked repository, ie. `git clone https://github.com/<your-username>/dev.to.git`
3.  Install bundler with `gem install bundler`
4.  Install foreman gem with `gem install foreman`
5.  Install our ruby dependencies with `bundle install`
6.  Install our frontend dependencies with `bin/yarn`
7.  Set up your environment variables/secrets

- Take a look at `Envfile`. This file lists all the `ENV` variables we use and provides a fake default for any missing keys. You'll need to get your own free [Algolia credentials](http://docs.dev.to/get-api-keys-dev-env/#algolia) to get your development environment running.
- This [guide](http://docs.dev.to/get-api-keys-dev-env/) will show you how to get free API keys for additional servies that may be required to run certain parts of the app.
- For any key that you wish to enter/replace:

8.  Create `config/application.yml` by copying from the provided template (ie. with bash: `cp config/sample_application.yml config/application.yml`). This is a personal file that is ignored in git.
9.  Obtain the development variable and apply the key you wish to enter/replace. ie:

    ```
    GITHUB_KEY: "SOME_REAL_SECURE_KEY_HERE"
    GITHUB_SECRET: "ANOTHER_REAL_SECURE_KEY_HERE"
    ```

- If you are missing `ENV` variables on bootup, `envied` gem will alert you with messages similar to `'error_on_missing_variables!': The following environment variables should be set: A_MISSING_KEY.`.
- You do not need "real" keys for basic development. Some features require certain keys, so you may be able to add them as you go.

10. Run `bin/setup`

#### Possible Error Messages

**Error:** `rbenv: version '<version number>' is not installed (set by /Path/To/Local/Repository/.ruby-version)`
**_Solution:_** Run the command `rbenv install <version number>`

> If you encountered any errors that you subsequently resolved, **please consider updating this section** with your errors and their solutions.
