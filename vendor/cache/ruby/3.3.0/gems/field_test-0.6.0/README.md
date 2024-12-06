# Field Test

:maple_leaf: A/B testing for Rails

- Designed for web and email
- Comes with a [dashboard](https://fieldtest.dokkuapp.com/) to view results and update variants
- Uses your database for storage
- Seamlessly handles the transition from anonymous visitor to logged in user

Uses [Bayesian statistics](https://www.evanmiller.org/bayesian-ab-testing.html) to evaluate results so you don’t need to choose a sample size ahead of time.

[![Build Status](https://github.com/ankane/field_test/workflows/build/badge.svg?branch=master)](https://github.com/ankane/field_test/actions)

## Installation

Add this line to your application’s Gemfile:

```ruby
gem "field_test"
```

Run:

```sh
rails generate field_test:install
rails db:migrate
```

And mount the dashboard in your `config/routes.rb`:

```ruby
mount FieldTest::Engine, at: "field_test"
```

Be sure to [secure the dashboard](#dashboard-security) in production.

## Getting Started

Add an experiment to `config/field_test.yml`.

```yml
experiments:
  button_color:
    variants:
      - red
      - green
      - blue
```

Refer to it in controllers, views, and mailers.

```ruby
button_color = field_test(:button_color)
```

To make testing easier, you can specify a variant with query parameters

```
http://localhost:3000/?field_test[button_color]=green
```

When someone converts, record it with:

```ruby
field_test_converted(:button_color)
```

When an experiment is over, specify a winner:

```yml
experiments:
  button_color:
    winner: green
```

All calls to `field_test` will now return the winner, and metrics will stop being recorded.

You can keep returning the variant for existing participants after a winner is declared:

```yml
experiments:
  button_color:
    winner: green
    keep_variant: true
```

You can also close an experiment to new participants without declaring a winner while still recording metrics for existing participants:

```yml
experiments:
  button_color:
    closed: true
```

Calls to `field_test` for new participants will return the control, and they won’t be added to the experiment.

You can get the list of experiments and variants for a user with:

```ruby
field_test_experiments
```

## JavaScript and Native Apps

For JavaScript and native apps, add calls to your normal endpoints.

```ruby
class CheckoutController < ActionController::API
  def start
    render json: {button_color: field_test(:button_color)}
  end

  def finish
    field_test_converted(:button_color)
    # ...
  end
end
```

For anonymous visitors in native apps, pass a `Field-Test-Visitor` header with a unique identifier.

## Participants

Any model or string can be a participant in an experiment.

For web requests, it uses `current_user` (if it exists) and an anonymous visitor id to determine the participant. Set your own with:

```ruby
class ApplicationController < ActionController::Base
  def field_test_participant
    current_company
  end
end
```

For mailers, it tries `@user` then `params[:user]` to determine the participant. Set your own with:

```ruby
class ApplicationMailer < ActionMailer::Base
  def field_test_participant
    @company
  end
end
```

You can also manually pass a participant with:

```ruby
field_test(:button_color, participant: company)
```

## Jobs

To get variants in jobs, models, and other contexts, use:

```ruby
experiment = FieldTest::Experiment.find(:button_color)
button_color = experiment.variant(user)
```

## Exclusions

By default, bots are returned the first variant and excluded from metrics. Change this with:

```yml
exclude:
  bots: false
```

Exclude certain IP addresses with:

```yml
exclude:
  ips:
    - 127.0.0.1
    - 10.0.0.0/8
```

You can also use custom logic:

```ruby
field_test(:button_color, exclude: request.user_agent == "Test")
```

## Config

Keep track of when experiments started and ended. Use any format `Time.parse` accepts. Variants assigned outside this window are not included in metrics.

```yml
experiments:
  button_color:
    started_at: Dec 1, 2016 8 am PST
    ended_at: Dec 8, 2016 2 pm PST
```

Add a friendlier name and description with:

```yml
experiments:
  button_color:
    name: Buttons!
    description: >
      Different button colors
      for the landing page.
```

By default, variants are given the same probability of being selected. Change this with:

```yml
experiments:
  button_color:
    variants:
      - red
      - blue
    weights:
      - 85
      - 15
```

To help with GDPR compliance, you can switch from cookies to [anonymity sets](https://privacypatterns.org/patterns/Anonymity-set) for anonymous visitors. Visitors with the same IP mask and user agent are grouped together.

```yml
cookies: false
```

## Dashboard Config

If the dashboard gets slow, you can make it faster with:

```yml
cache: true
```

This will use the Rails cache to speed up winning probability calculations.

If you need more precision, set:

```yml
precision: 1
```

## Multiple Goals

You can set multiple goals for an experiment to track conversions at different parts of the funnel. First, run:

```sh
rails generate field_test:events
rails db:migrate
```

And add to your config:

```yml
experiments:
  button_color:
    goals:
      - signed_up
      - ordered
```

Specify a goal during conversion with:

```ruby
field_test_converted(:button_color, goal: "ordered")
```

The results for all goals will appear on the dashboard.

## Analytics Platforms

You may also want to send experiment data as properties to other analytics platforms like [Segment](https://segment.com), [Amplitude](https://amplitude.com), and [Ahoy](https://github.com/ankane/ahoy). Get the list of experiments and variants with:

```ruby
field_test_experiments
```

### Ahoy

You can configure Field Test to use Ahoy’s visitor token instead of creating its own:

```ruby
class ApplicationController < ActionController::Base
  def field_test_participant
    [ahoy.user, ahoy.visitor_token]
  end
end
```

## Dashboard Security

#### Devise

```ruby
authenticate :user, ->(user) { user.admin? } do
  mount FieldTest::Engine, at: "field_test"
end
```

#### Basic Authentication

Set the following variables in your environment or an initializer.

```ruby
ENV["FIELD_TEST_USERNAME"] = "moonrise"
ENV["FIELD_TEST_PASSWORD"] = "kingdom"
```

## Updating Variants

Assign a specific variant to a user with:

```ruby
experiment = FieldTest::Experiment.find(:button_color)
experiment.variant(participant, variant: "green")
```

You can also change a user’s variant from the dashboard.

## Associations

To associate models with field test memberships, use:

```ruby
class User < ApplicationRecord
  has_many :field_test_memberships, class_name: "FieldTest::Membership", as: :participant
end
```

Now you can do:

```ruby
user.field_test_memberships
```

## Credits

A huge thanks to [Evan Miller](https://www.evanmiller.org/) for deriving the Bayesian formulas.

## History

View the [changelog](https://github.com/ankane/field_test/blob/master/CHANGELOG.md)

## Contributing

Everyone is encouraged to help improve this project. Here are a few ways you can help:

- [Report bugs](https://github.com/ankane/field_test/issues)
- Fix bugs and [submit pull requests](https://github.com/ankane/field_test/pulls)
- Write, clarify, or fix documentation
- Suggest or add new features

To get started with development:

```sh
git clone https://github.com/ankane/field_test.git
cd field_test
bundle install
bundle exec rake compile
bundle exec rake test
```
