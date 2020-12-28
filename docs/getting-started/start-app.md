---
title: Starting the Application
---

We're a Rails app, and we use [Webpacker][webpacker] to manage some of our
JavaScript.

# Starting the application

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

# Starting the application (advanced)

To have additional control in your local environment, you might prefer using an
advanced setup to start the application by using [Overmind][overmind].

The prerequisite is to install [Overmind][overmind], a process manager which
takes advantage of [tmux][tmux].

This will allow you to launch all your app's processes in the same terminal, navigate the logs
of each service separately, restart each service separately and have a better
debugging experience.

After installing [Overmind][overmind], launch the application:

```shell
overmind s -f Procfile.dev
```

## Debugging the Rails application

[Overmind][overmind] lets you easily step through the Rails application in a
debugging session.

Using the `pry` gem, you can add a `binding.pry` to set a breakpoint in the method you're trying to
debug; the application will halt its execution there. You can then connect
to the web server by opening a separate terminal window and typing:

```shell
overmind c web
```

This will open up a [tmux][tmux] window pane at the debugging statement
position, which will look something like this:

```ruby
pry(#<Admin::AdminPortalsController>)> whereami

From: /forem/app/controllers/admin/admin_portals_controller.rb:8 Admin::AdminPortalsController#index:

    5: def index
    6:   a = "Hello debugger"
    7:   binding.pry
 => 8: end
```

## Inspecting the logs of each service

Overmind launches the various services required for our local setup: `web` (the
Rails web server), `webpacker` (the server managing JavaScript) and `sidekiq`
(the server managing the asynchronous queue).

If, for example, you want to inspect just the Sidekiq logs, you can open a
separate terminal window to look at those logs specifically:

```shell
overmind c sidekiq
```

This will open a `tmux` console, which will allow you to browse _only_ the Sidekiq logs.

There are also some handy `tmux` shortcuts that you may find useful.

* The shortcut `C-b [` (_Control-b-open square bracket_) activates "scroll
mode", which allows you to use the arrows up and down and inspect the logs.
* The shortcut `q` deactivates "scroll mode".

Please refer to [tmux][tmux] documentation for more information around `tmux` configuration and for additional
shortcuts.

## Resources

Other than the official [Overmind][overmind] and [tmux][tmux]
documentation, you may find the following resources useful:

- [Rails quick tips #6: tmux, tmuxinator and Overmind](https://dev.to/citizen428/rails-quick-tips-6-tmux-tmuxinator-and-overmind-4850)
- [Give Your Terminal Super Powers: tmux Cheatsheet!](https://dev.to/jacobherrington/give-your-terminal-super-powers-tmux-cheatsheet-1p6p)
- [Introducing Overmind and Hivemind](https://evilmartians.com/chronicles/introducing-overmind-and-hivemind)

[sidekiq]: https://github.com/mperham/sidekiq
[webpacker]: https://github.com/rails/webpacker
[overmind]: https://github.com/DarthSim/overmind
[tmux]: https://github.com/tmux/tmux/wiki
