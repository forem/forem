---
title: Starting the Application
---

# Starting the application

We're a Rails app, and we use [Webpacker][webpacker] to manage some of our
JavaScript.

Start the application, Webpack, and our job runner [Sidekiq][sidekiq] by
running:

```shell
bin/startup
```

(This just runs `foreman start -f Procfile.dev`, for notes on how to install
Foreman, please see [Other Tools](/installation/others/))

Then point your browser to http://localhost:3000/ to view the site. To log in
use the admin account created by default (see
[Database](/getting-started/db/#default-admin-user))

If you run into issues while trying to run `bin/setup` and the error message
isn't helpful, try running `bin/rails s -p 3000`. For example, you may need to
`yarn install` before starting the app.

If Sidekiq is producing errors similar to
`No such file or directory - [SOME FILE]`, you may need to start Sidekiq by
itself once to help it initialize itself fully. You can use the command
`bundle exec sidekiq` to do this.

If you're working on Forem regularly, you can use `alias start="bin/startup"` to
make this even easier. 😊

If you're using **`pry`** for debugging in Rails, note that using `foreman` and
`pry` together works, but it's not as clean as `bin/rails server`.

Here are some singleton commands you may need, usually in a separate
instance/tab of your shell.

- Running the job Sidekiq server (if using `bin/rails server`) -- this is mostly
  for notifications and emails: **`bundle exec sidekiq`**

Current gotchas: potential environment issues with external services need to be
worked out.

[sidekiq]: https://github.com/mperham/sidekiq
[webpacker]: https://github.com/rails/webpacker
