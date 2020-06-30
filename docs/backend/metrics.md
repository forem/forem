---
title: Metrics
---

## Time series data

We track point-in-time data by sending data points to Datadog using
[Statdsd](https://github.com/DataDog/dogstatsd-ruby).

Currently, we run a daily metric fetching job in `fetch.rake` which is called
via the Heroku scheduler. If we wanted to do other frequencies like hourly, etc.
we could add similar tasks.

The rake task calls `Metrics::RecordDailyUsageWorker.perform_async`, which
performs algorithms to come up with data points to send, for example:

```ruby
DataDogStatsClient.count("users.active_days_past_week", one_day_users, tags: { resource: "users", group: "new_users, day_count: 1 })
```

If you want to create a new periodic data send, follow this pattern to do so.

## Vendor-Agnostic

While we currently are not vendor-agnostic in how we do this (Heroku/Datadog),
it is set up in a way that could become so in the future. The main pattern is
`Every x minutes/hours/etc. send aggregate data to warehouse where it can be examined on a timeseries basis`.
This could, in the future, be bundled right into the platform using an open
source timeseries database and data visualization.

Once in Datadog, dashboards can created using

![Datadog metrics](https://dev-to-uploads.s3.amazonaws.com/i/98rju6kzxeosf6m0jfhy.png)
