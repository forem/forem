---
title: Configuring Environment Variables
---

# Configuring environment variables and secret keys

Take a look at `Envfile`. This file lists all the `ENV` variables we use and
provides a fake default for any missing keys.

The [backend guide][backend_guide] will show you how to get free API keys for
additional services that may be required to run certain parts of the app.

To set up keys for your local instance of Forem, you'll need to create an
`application.yml` file. You can do this by copying the file called
`sample_application.yml` in the `config` directory:

```shell
cp config/sample_application.yml config/application.yml
```

Then, add each key you need to the `application.yml` file. For example, if
you're setting up GitHub authentication:

```shell
GITHUB_KEY: "SOME_REAL_SECURE_KEY_HERE"
GITHUB_SECRET: "ANOTHER_REAL_SECURE_KEY_HERE"
```

(Don't worry, your `application.yml` file is ignored by git)

If you are missing `ENV` variables on bootup, the [envied][envied] gem will
alert you with messages similar to
`'error_on_missing_variables!': The following environment variables should be set: A_MISSING_KEY.`.

Only certain features require "real" keys, so you may be able to add them as you
work on different areas of the application.

[backend_guide]: /backend
[envied]: https://rubygems.org/gems/envied
