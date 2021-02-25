---
title: Configuring Environment Variables
---

# Configuring environment variables and secret keys

Take a look at `.env_sample`. This file lists all the `ENV` variables we use and
provides a fake default for any missing keys.

The [backend guide][backend_guide] will show you how to get free API keys for
additional services that may be required to run certain parts of the app.

To set up keys for your local instance of Forem, you'll need to create an `.env`
file. You can do this by copying the file called `.env_sample` in the app's main
directory:

```shell
cp .env_sample .env
```

Then, add each key you need to the `.env` file. For example, if you're setting
up Cloudinary:

```shell
export CLOUDINARY_API_KEY="SOME_REAL_SECURE_KEY_HERE"
export CLOUDINARY_API_SECRET="ANOTHER_REAL_SECURE_KEY_HERE"
export CLOUDINARY_CLOUD_NAME="A_CLOUDINARY_NAME"
```

(Don't worry, your `.env` file is ignored by git)

If you are missing `ENV` variables when you boot your application you will see a
warning message in your logs when you try to access that variable
`Unset ENV variable: xyz`.

Only certain features require "real" keys, so you may be able to add them as you
work on different areas of the application.

[backend_guide]: /backend
