---
title: Starting the Application
---

# Starting the Application

We're mostly a Rails app, with a bit of Webpack sprinkled in. **For most cases, simply running `bin/rails server` will do.** If you're working with Webpack though, you'll need to run the following:

- Run **`bin/startup`** to start the server, Webpack, and our job runner `delayed_job`. `bin/startup` runs `foreman start -f Procfile.dev` under the hood.
- `alias start="bin/startup"` makes this even faster. 😊
- If you're using **`pry`** for debugging in Rails, note that using `foreman` and `pry` together works, but it's not as clean as `bin/rails server`.

Here are some singleton commands you may need, usually in a separate instance/tab of your shell.

- Running the job server (if using `bin/rails server`) -- this is mostly for notifications and emails: **`bin/rails jobs:work`**
- Clearing jobs (in case you don't want to wait for the backlog of jobs): **`bin/rails jobs:clear`**

Current gotchas: potential environment issues with external services need to be worked out.
