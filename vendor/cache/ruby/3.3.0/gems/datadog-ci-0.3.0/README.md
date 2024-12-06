# Datadog CI Visibility for Ruby

[![Gem Version](https://badge.fury.io/rb/datadog-ci.svg)](https://badge.fury.io/rb/datadog-ci)
[![codecov](https://codecov.io/gh/DataDog/datadog-ci-rb/branch/main/graph/badge.svg)](https://app.codecov.io/gh/DataDog/datadog-ci-rb/branch/main)
[![CircleCI](https://dl.circleci.com/status-badge/img/gh/DataDog/datadog-ci-rb/tree/main.svg?style=svg)](https://dl.circleci.com/status-badge/redirect/gh/DataDog/datadog-ci-rb/tree/main)

Datadog's Ruby Library for instrumenting your test and continuous integration pipeline.
Learn more on our [official website](https://docs.datadoghq.com/continuous_integration/tests/ruby/).

> [!IMPORTANT]
> The `datadog-ci` gem is currently a component of [`ddtrace`](https://github.com/datadog/dd-trace-rb) and should not be used without it.
>
> We expect this to change in the future.

## Installation

Add to your Gemfile.

```ruby
gem "ddtrace"
```

## Usage

### RSpec

To activate `RSpec` integration, add this to the `spec_helper.rb` file:

```ruby
require 'rspec'
require 'datadog/ci'

Datadog.configure do |c|
  # Only activates test instrumentation on CI
  c.tracing.enabled = (ENV["DD_ENV"] == "ci")

  # Configures the tracer to ensure results delivery
  c.ci.enabled = true

  # The name of the service or library under test
  c.service = 'my-ruby-app'

  # Enables the RSpec instrumentation
  c.ci.instrument :rspec, **options
end
```

`options` are the following keyword arguments:

| Key | Description | Default |
| --- | ----------- | ------- |
| `enabled` | Defines whether RSpec tests should be traced. Useful for temporarily disabling tracing. `true` or `false` | `true` |
| `service_name` | Service name used for `rspec` instrumentation. | `'rspec'` |
| `operation_name` | Operation name used for `rspec` instrumentation. Useful if you want rename automatic trace metrics e.g. `trace.#{operation_name}.errors`. | `'rspec.example'` |

### Minitest

The Minitest integration will trace all executions of tests when using `minitest` test framework.

To activate your integration, use the `Datadog.configure` method:

```ruby
require 'minitest'
require 'datadog/ci'

# Configure default Minitest integration
Datadog.configure do |c|
  # Only activates test instrumentation on CI
  c.tracing.enabled = (ENV["DD_ENV"] == "ci")

  # Configures the tracer to ensure results delivery
  c.ci.enabled = true

  # The name of the service or library under test
  c.service = 'my-ruby-app'

  c.ci.instrument :minitest, **options
end
```

`options` are the following keyword arguments:

| Key | Description | Default |
| --- | ----------- | ------- |
| `enabled` | Defines whether Minitest tests should be traced. Useful for temporarily disabling tracing. `true` or `false` | `true` |
| `service_name` | Service name used for `minitest` instrumentation. | `'minitest'` |
| `operation_name` | Operation name used for `minitest` instrumentation. Useful if you want rename automatic trace metrics e.g. `trace.#{operation_name}.errors`. | `'minitest.test'` |

### Cucumber

Activate `Cucumber` integration with configuration

```ruby
require 'cucumber'
require 'datadog/ci'

Datadog.configure do |c|
  # Only activates test instrumentation on CI
  c.tracing.enabled = (ENV["DD_ENV"] == "ci")

  # Configures the tracer to ensure results delivery
  c.ci.enabled = true

  # The name of the service or library under test
  c.service = 'my-ruby-app'

  # Enables the Cucumber instrumentation
  c.ci.instrument :cucumber, **options
end
```

`options` are the following keyword arguments:

| Key | Description | Default |
| --- | ----------- | ------- |
| `enabled` | Defines whether Cucumber tests should be traced. Useful for temporarily disabling tracing. `true` or `false` | `true` |
| `service_name` | Service name used for `cucumber` instrumentation. | `'cucumber'` |
| `operation_name` | Operation name used for `cucumber` instrumentation. Useful if you want rename automatic trace metrics e.g. `trace.#{operation_name}.errors`. | `'cucumber.test'` |

## Agentless mode

If you are using a cloud CI provider without access to the underlying worker nodes, such as GitHub Actions or CircleCI, configure the library to use the Agentless mode. For this, set the following environment variables:
`DD_CIVISIBILITY_AGENTLESS_ENABLED=true (Required)` and `DD_API_KEY=your_secret_api_key (Required)`.

Additionally, configure which [Datadog site](https://docs.datadoghq.com/getting_started/site/) you want to send data to:
`DD_SITE=your.datadoghq.com` (datadoghq.com by default).

Agentless mode can also be enabled via `Datadog.configure` (but don't forget to set DD_API_KEY environment variable):

```ruby
Datadog.configure { |c| c.ci.agentless_mode_enabled = true }
```

## Additional configuration

### Add tracing instrumentations

It can be useful to have rich tracing information about your tests that includes time spent performing database operations
or other external calls like here:

![Test trace with redis instrumented](./docs/screenshots/test-trace-with-redis.png)

In order to achieve this you can configure ddtrace instrumentations in your configure block:

```ruby
Datadog.configure do |c|
  #  ... ci configs and instrumentation here ...
  c.instrument :redis
  c.instrument :pg
end
```

...or enable auto instrumentation in your test_helper/spec_helper:

```ruby
require "ddtrace/auto_instrument"
```

Note: in CI mode these traces are going to be submitted to CI Visibility,
they will **not** show up in Datadog APM.

For the full list of available instrumentations see [ddtrace documentation](https://github.com/DataDog/dd-trace-rb/blob/master/docs/GettingStarted.md)

### Disabling startup logs

Startup logs produce a report of tracing state when the application is initially configured.
These logs are activated by default in test mode, if you don't want them you can disable this
via `diagnostics.startup_logs.enabled = false` or `DD_TRACE_STARTUP_LOGS=0`.

```ruby
Datadog.configure { |c| c.diagnostics.startup_logs.enabled = false }
```

### Enabling debug mode

Switching the library into debug mode will produce verbose, detailed logs about tracing activity, including any suppressed errors. This output can be helpful in identifying errors, confirming trace output, or catching HTTP transport issues.

You can enable this via `diagnostics.debug = true` or `DD_TRACE_DEBUG=1`.

```ruby
Datadog.configure { |c| c.diagnostics.debug = true }
```

## Contributing

See [development guide](/docs/DevelopmentGuide.md), [static typing guide](docs/StaticTypingGuide.md) and [contributing guidelines](/CONTRIBUTING.md).

## Code of Conduct

Everyone interacting in the `Datadog::CI` project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](/CODE_OF_CONDUCT.md).
