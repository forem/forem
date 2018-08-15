## Installing prerequisites

### Ruby

1.  If you don't already a Ruby version manager, we highly recommend [rbenv](https://github.com/rbenv/rbenv). Please follow their [installation guide](https://github.com/rbenv/rbenv#installation).
2.  With the Ruby version manager, install Ruby verion listed on our badge. (ie with rbenv: `rbenv install 2.5.1`)

### Yarn

Please refer to their [installation guide](https://yarnpkg.com/en/docs/install).

### PostgreSQL

The easiest way to get started is to use [Postgres.app](https://postgresapp.com/). Alternatively, you may check out the official [PostgreSQL](https://www.postgresql.org/) site for more granular version.

## Getting the app running

1.  `git clone git@github.com:thepracticaldev/dev.to.git`
1.  `gem install bundler`
1.  `gem install foreman`
1.  `bundle install`
1.  `bin/yarn`
1.  Set up your environment variables/secrets

* Take a look at `Envfile`. This file lists all the `ENV` variables we use and provides a fake default for any missing keys. You'll need to get your own free [Algolia credentials](http://docs.dev.to/get-api-keys-dev-env/#algolia) to get your development environment running.
* This [guide](http://docs.dev.to/get-api-keys-dev-env/) will show you how to get free API keys for additional servies that may be required to run certain parts of the app.
* For any key that you wish to enter/replace:

1.  Create `config/application.yml` by copying from the provided template (ie. with bash: `cp config/sample_application.yml config/application.yml`). This is a personal file that is ignored in git.
2.  Obtain the development variable and apply the key you wish to enter/replace. ie:


    ```
    GITHUB_KEY: "afaslkjdflkj2398jflskdjfljk"
    GITHUB_SECRET: "23r8dcvlk23jekljfslkdfjlks"
    ```

* If you are missing `ENV` variables on bootup, `envied` gem will alert you with messages similar to `'error_on_missing_variables!': The following environment variables should be set: A_MISSING_KEY.`.
* You do not need "real" keys for basic development. Some features require certain keys, so you may be able to add them as you go.

1.  Run `bin/setup`
