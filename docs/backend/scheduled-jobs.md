---
title: Scheduled Jobs
---

# Scheduled Jobs

As in the [Technical Overview](/technical-overview), We use
[Heroku Scheduler](https://devcenter.heroku.com/articles/scheduler) for
scheduled jobs. As the name suggests, this is for regularly recurring tasks that
need to be run every day, week, month, year, decade, and century.

Tasks are implemented in `forem/lib/tasks/fetch.rake`, typically in the form of:

```
task some_unique_task_name:, [optional_arg] => :environment do |optional_arg|
  ... do your thing here ...
end
```

You can explore the
[official Heroku documentation](https://devcenter.heroku.com/articles/scheduler#defining-tasks)
for defining tasks and read through tasks we have implemented for busting cache,
awarding badges, and more.

In your Pull Request, communicate with a Forem Core Team Member to discuss at
what frequency and ensure your task is scheduled on Heroku once your code is
reviewed, approved, and merged.
