# Safely

```ruby
safely do
  # keep going if this code fails
end
```

Exceptions are rescued and automatically reported to your favorite reporting service.

In development and test environments, exceptions are raised so you can fix them.

[Read more](https://ankane.org/safely-pattern)

[![Build Status](https://github.com/ankane/safely/actions/workflows/build.yml/badge.svg)](https://github.com/ankane/safely/actions)

## Installation

Add this line to your application’s Gemfile:

```ruby
gem "safely_block"
```

## Use It Everywhere

“Oh no, analytics brought down search”

```ruby
safely { track_search(params) }
```

“Recommendations stopped updating because of one bad user”

```ruby
users.each do |user|
  safely(context: {user_id: user.id}) { update_recommendations(user) }
end
```

Also aliased as `yolo`

## Features

Pass extra context to be reported with exceptions

```ruby
safely context: {user_id: 123} do
  # code
end
```

Specify a default value to return on exceptions

```ruby
show_banner = safely(default: true) { show_banner_logic }
```

Raise specific exceptions

```ruby
safely except: ActiveRecord::RecordNotUnique do
  # all other exceptions will be rescued
end
```

Pass an array for multiple exception classes.

Rescue only specific exceptions

```ruby
safely only: ActiveRecord::RecordNotUnique do
  # all other exceptions will be raised
end
```

Silence exceptions

```ruby
safely silence: ActiveRecord::RecordNotUnique do
  # code
end
```

Throttle reporting with:

```ruby
safely throttle: {limit: 10, period: 1.minute} do
  # reports only first 10 exceptions each minute
end
```

**Note:** The throttle limit is approximate and per process.

## Reporting

Reports exceptions to a variety of services out of the box.

- [Airbrake](https://airbrake.io/)
- [Appsignal](https://appsignal.com/)
- [Bugsnag](https://bugsnag.com/)
- [Datadog](https://www.datadoghq.com/product/error-tracking/)
- [Exception Notification](https://github.com/smartinez87/exception_notification)
- [Google Stackdriver](https://cloud.google.com/stackdriver/)
- [Honeybadger](https://www.honeybadger.io/)
- [New Relic](https://newrelic.com/)
- [Raygun](https://raygun.io/)
- [Rollbar](https://rollbar.com/)
- [Scout APM](https://scoutapm.com/)
- [Sentry](https://getsentry.com/)

**Note:** Context is not supported with Google Stackdriver and Scout APM

Customize reporting with:

```ruby
Safely.report_exception_method = ->(e) { Rollbar.error(e) }
```

With Rails, you can add this in an initializer.

By default, exception messages are prefixed with `[safely]`. This makes it easier to spot rescued exceptions. Turn this off with:

```ruby
Safely.tag = false
```

To report exceptions manually:

```ruby
Safely.report_exception(e)
```

## Data Protection

To protect the privacy of your users, do not send [personal data](https://en.wikipedia.org/wiki/Personally_identifiable_information) to exception services. Filter sensitive form fields, use ids (not email addresses) to identify users, and mask IP addresses.

With Rollbar, you can do:

```ruby
Rollbar.configure do |config|
  config.person_id_method = "id" # default
  config.scrub_fields |= [:birthday]
  config.anonymize_user_ip = true
end
```

While working on exceptions, be on the lookout for personal data and correct as needed.

## History

View the [changelog](https://github.com/ankane/safely/blob/master/CHANGELOG.md)

## Contributing

Everyone is encouraged to help improve this project. Here are a few ways you can help:

- [Report bugs](https://github.com/ankane/safely/issues)
- Fix bugs and [submit pull requests](https://github.com/ankane/safely/pulls)
- Write, clarify, or fix documentation
- Suggest or add new features

To get started with development and testing:

```sh
git clone https://github.com/ankane/safely.git
cd safely
bundle install
bundle exec rake test
```
