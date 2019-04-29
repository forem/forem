---
title: Configure Enviroment Variables
---

# Set up your environment variables/secrets

- Take a look at `Envfile`. This file lists all the `ENV` variables we use and provides a fake default for any missing keys. You'll need to get your own free [Algolia credentials](http://docs.dev.to/get-api-keys-dev-env/#algolia) to get your development environment running.
- This [guide](http://docs.dev.to/get-api-keys-dev-env/) will show you how to get free API keys for additional services that may be required to run certain parts of the app.
- For any key that you wish to enter/replace:
  1.  Create `config/application.yml` by copying from the provided template (ie. with bash: `cp config/sample_application.yml config/application.yml`). This is a personal file that is ignored in git.
  2.  Obtain the development variable and apply the key you wish to enter/replace. ie:
  ```
  GITHUB_KEY: "SOME_REAL_SECURE_KEY_HERE"
  GITHUB_SECRET: "ANOTHER_REAL_SECURE_KEY_HERE"
  ```
- If you are missing `ENV` variables on bootup, `envied` gem will alert you with messages similar to `'error_on_missing_variables!': The following environment variables should be set: A_MISSING_KEY.`.
- You do not need "real" keys for basic development. Some features require certain keys, so you may be able to add them as you go.
