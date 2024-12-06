# stripe-ruby-mock [![Build Status](https://travis-ci.org/stripe-ruby-mock/stripe-ruby-mock.png?branch=master)](https://travis-ci.org/stripe-ruby-mock/stripe-ruby-mock) [![Gitter chat](https://badges.gitter.im/rebelidealist/stripe-ruby-mock.png)](https://gitter.im/rebelidealist/stripe-ruby-mock)

* Homepage: https://github.com/stripe-ruby-mock/stripe-ruby-mock
* Issues: https://github.com/stripe-ruby-mock/stripe-ruby-mock/issues
* **CHAT**: https://gitter.im/rebelidealist/stripe-ruby-mock

# REQUEST: Looking for More Core Contributors

This gem has unexpectedly grown in popularity and I've gotten pretty busy, so I'm currently looking for more core contributors to help me out. If you're interested, there is only one requirement: submit a significant enough pull request and have it merged into master (many of you have already done this). Afterwards, ping [@gilbert](https://gitter.im/gilbert) in [chat](https://gitter.im/rebelidealist/stripe-ruby-mock) and I will add you as a collaborator.

## Install

In your gemfile:

    gem 'stripe-ruby-mock', '~> 3.0.1', :require => 'stripe_mock'

## !!! Important

We have [changelog](https://github.com/stripe-ruby-mock/stripe-ruby-mock/blob/master/CHANGELOG.md). It's first attempt. Feel free to update it and suggest to a new format of it.

version `3.0.0` has [breaking changes](https://github.com/stripe-ruby-mock/stripe-ruby-mock/pull/658) - we support stripe > 5 and < 6 for now and try to follow the newest API version. But if you still use older versions please [read](https://github.com/stripe-ruby-mock/stripe-ruby-mock#specifications).

## Features

* No stripe server access required
* Easily test against stripe errors
* Mock and customize stripe webhooks
* Flip a switch to run your tests against Stripe's **live test servers**

### Requirements

* ruby >= 2.4.0
* stripe >= 5.0.0

### Specifications

**STRIPE API TARGET VERSION:** 2019-08-20 (master) - we try, but some features are not implemented yet.

Older API version branches:

- api-2015-09-08 - use gem version 2.4.1
- [api-2014-06-17](https://github.com/rebelidealist/stripe-ruby-mock/tree/api-2014-06-17)

### Versioning System

Since StripeMock tries to keep up with Stripe's API version, its version system is a little different:

- The **major** number (1.x.x) is for breaking changes involving how you use StripeMock itself
- The **minor** number (x.1.x) is for breaking changes involving Stripe's API
- The **patch** number (x.x.0) is for non-breaking changes/fixes involving Stripe's API, or for non-breaking changes/fixes/features for StripeMock itself.

## Description

** *WARNING: This library does not cover all Stripe API endpoints. If you need one that's missing, please create an issue for it, or [see this wiki page](https://github.com/rebelidealist/stripe-ruby-mock/wiki/Implementing-a-New-Behavior) if you're interested in contributing* **

At its core, this library overrides [stripe-ruby's](https://github.com/stripe/stripe-ruby)
request method to skip all http calls and
instead directly return test data. This allows you to write and run tests
without the need to actually hit stripe's servers.

You can use stripe-ruby-mock with any ruby testing library. Here's a quick dummy example with RSpec:

```ruby
require 'stripe_mock'

describe MyApp do
  let(:stripe_helper) { StripeMock.create_test_helper }
  before { StripeMock.start }
  after { StripeMock.stop }

  it "creates a stripe customer" do

    # This doesn't touch stripe's servers nor the internet!
    # Specify :source in place of :card (with same value) to return customer with source data
    customer = Stripe::Customer.create({
      email: 'johnny@appleseed.com',
      source: stripe_helper.generate_card_token
    })
    expect(customer.email).to eq('johnny@appleseed.com')
  end
end
```

## Test Helpers

Some Stripe API calls require several parameters. StripeMock helps you keep your test brief with some helpers:

```ruby
describe MyApp do
  let(:stripe_helper) { StripeMock.create_test_helper }

  it "creates a stripe plan" do
    plan = stripe_helper.create_plan(:id => 'my_plan', :amount => 1500)

    # The above line replaces the following:
    # plan = Stripe::Plan.create(
    #   :id => 'my_plan',
    #   :name => 'StripeMock Default Plan ID',
    #   :amount => 1500,
    #   :currency => 'usd',
    #   :interval => 'month'
    # )
    expect(plan.id).to eq('my_plan')
    expect(plan.amount).to eq(1500)
  end
end
```

The [available helpers](lib/stripe_mock/test_strategies/) are:

```ruby
stripe_helper.create_plan(my_plan_params)
stripe_helper.delete_plan(my_plan_params)
stripe_helper.generate_card_token(my_card_params)
```

For everything else, use Stripe as you normally would (i.e. use Stripe as if you were not using StripeMock).

## Live Testing

Every once in a while you want to make sure your tests are actually valid. StripeMock has a switch that allows you to run your test suite (or a subset thereof) against Stripe's live test servers.

Here is an example of setting up your RSpec (2.x) test suite to run live with a command line switch:

```ruby
# RSpec 2.x
RSpec.configure do |c|
  if c.filter_manager.inclusions.keys.include?(:live)
    StripeMock.toggle_live(true)
    puts "Running **live** tests against Stripe..."
  end
end
```

With this you can run live tests by running `rspec -t live`

Here is an example of setting up your RSpec (3.x) test suite to run live with the same command line switch:

```ruby
# RSpec 3.x
RSpec.configure do |c|
  if c.filter_manager.inclusions.rules.include?(:live)
    StripeMock.toggle_live(true)
    puts "Running **live** tests against Stripe..."
  end
end
```

## Mocking Card Errors
** Ensure you start StripeMock in a before filter `StripeMock.start`
Tired of manually inputting fake credit card numbers to test against errors? Tire no more!

```ruby
it "mocks a declined card error" do
  # Prepares an error for the next create charge request
  StripeMock.prepare_card_error(:card_declined)

  expect { Stripe::Charge.create(amount: 1, currency: 'usd') }.to raise_error {|e|
    expect(e).to be_a Stripe::CardError
    expect(e.http_status).to eq(402)
    expect(e.code).to eq('card_declined')
  }
end
```

### Built-In Card Errors

```ruby
StripeMock.prepare_card_error(:incorrect_number)
StripeMock.prepare_card_error(:invalid_number)
StripeMock.prepare_card_error(:invalid_expiry_month)
StripeMock.prepare_card_error(:invalid_expiry_year)
StripeMock.prepare_card_error(:invalid_cvc)
StripeMock.prepare_card_error(:expired_card)
StripeMock.prepare_card_error(:incorrect_cvc)
StripeMock.prepare_card_error(:card_declined)
StripeMock.prepare_card_error(:missing)
StripeMock.prepare_card_error(:processing_error)
StripeMock.prepare_card_error(:incorrect_zip)
```

You can see the details of each error in [lib/stripe_mock/api/errors.rb](lib/stripe_mock/api/errors.rb)

### Specifying Card Errors
** Ensure you start StripeMock in a before filter `StripeMock.start`
By default, `prepare_card_error` only triggers for `:new_charge`, the event that happens when you run `Charge.create`. More explicitly, this is what happens by default:

```ruby
StripeMock.prepare_card_error(:card_declined, :new_charge)
```

If you want the error to trigger on a different event, you need to replace `:new_charge` with a different event. For example:

```ruby
StripeMock.prepare_card_error(:card_declined, :create_card)
customer = Stripe::Customer.create
# This line throws the card error
customer.cards.create
```

`:new_charge` and `:create_card` are names of methods in the [StripeMock request handlers](lib/stripe_mock/request_handlers). You can also set `StripeMock.toggle_debug(true)` to see the event name for each Stripe request made in your tests.

### Custom Errors
** Ensure you start StripeMock in a before filter `StripeMock.start`
To raise an error on a specific type of request, take a look at the [request handlers folder](lib/stripe_mock/request_handlers/) and pass a method name to `StripeMock.prepare_error`.

If you wanted to raise an error for creating a new customer, for instance, you would do the following:

```ruby
it "raises a custom error for specific actions" do
  custom_error = StandardError.new("Please knock first.")

  StripeMock.prepare_error(custom_error, :new_customer)

  expect { Stripe::Charge.create(amount: 1, currency: 'usd') }.to_not raise_error
  expect { Stripe::Customer.create }.to raise_error {|e|
    expect(e).to be_a StandardError
    expect(e.message).to eq("Please knock first.")
  }
end
```

In the above example, `:new_customer` is the name of a method from [customers.rb](lib/stripe_mock/request_handlers/customers.rb).

## Running the Mock Server

Sometimes you want your test stripe data to persist for a bit, such as during integration tests
running on different processes. In such cases you'll want to start the stripe mock server:

    # spec_helper.rb
    #
    # The mock server will automatically be killed when your tests are done running.
    #
    require 'thin'
    StripeMock.spawn_server

Then, instead of `StripeMock.start`, you'll want to use `StripeMock.start_client`:

```ruby
describe MyApp do
  before do
    @client = StripeMock.start_client
  end

  after do
    StripeMock.stop_client
    # Alternatively:
    #   @client.close!
    # -- Or --
    #   StripeMock.stop_client(:clear_server_data => true)
  end
end
```

This is all essentially the same as using `StripeMock.start`, except that the stripe test
data is held in its own server process.

Here are some other neat things you can do with the client:

```ruby
@client.state #=> 'ready'

@client.get_server_data(:customers) # Also works for :charges, :plans, etc.
@client.clear_server_data

@client.close!
@client.state #=> 'closed'
```

### Mock Server Options

```ruby
# NOTE: Shown below are the default options
StripeMock.default_server_pid_path = './stripe-mock-server.pid'

StripeMock.spawn_server(
  :pid_path => StripeMock.default_server_pid_path,
  :host => '0.0.0.0',
  :port => 4999,
  :server => :thin
)

StripeMock.kill_server(StripeMock.default_server_pid_path)
```

### Mock Server Command

If you need the mock server to continue running even after your tests are done,
you'll want to use the executable:

    $ stripe-mock-server -p 4000
    $ stripe-mock-server --help

## Mocking Webhooks

If your application handles stripe webhooks, you are most likely retrieving the event from
stripe and passing the result to a handler. StripeMock helps you by easily mocking that event:

```ruby
it "mocks a stripe webhook" do
  event = StripeMock.mock_webhook_event('customer.created')

  customer_object = event.data.object
  expect(customer_object.id).to_not be_nil
  expect(customer_object.default_card).to_not be_nil
  # etc.
end

it "mocks stripe connect webhooks" do
  event = StripeMock.mock_webhook_event('customer.created', account: 'acc_123123')

  expect(event.account).to eq('acc_123123')
end
```

### Customizing Webhooks

By default, StripeMock searches in your `spec/fixtures/stripe_webhooks/` folder for your own, custom webhooks.
If it finds nothing, it falls back to [test events generated through stripe's webhooktester](lib/stripe_mock/webhook_fixtures/).

For example, you could create a file in `spec/fixtures/stripe_webhooks/invoice.created.with-sub.json`, copy/paste the default from [the default invoice.created.json](lib/stripe_mock/webhook_fixtures/invoice.created.json), and customize it to your needs.

Then you can use that webook directly in your specs:

```ruby
it "can use a custom webhook fixture" do
  event = StripeMock.mock_webhook_event('invoice.created.with-sub')
  # etc.
end
```

You can alse override values on the fly:

```ruby
it "can override webhook values" do
  # NOTE: given hash values get merged directly into event.data.object
  event = StripeMock.mock_webhook_event('customer.created', {
    :id => 'cus_my_custom_value',
    :email => 'joe@example.com'
  })
  # Alternatively:
  # event.data.object.id = 'cus_my_custom_value'
  # event.data.object.email = 'joe@example.com'
  expect(event.data.object.id).to eq('cus_my_custom_value')
  expect(event.data.object.email).to eq('joe@example.com')
end
```

You can name events whatever you like in your `spec/fixtures/stripe_webhooks/` folder. However, if you try to call a non-standard event that's doesn't exist in that folder, StripeMock will throw an error.

If you wish to use a different fixture path, you can set it yourself:

    StripeMock.webhook_fixture_path = './spec/other/folder/'

## Generating Card Tokens

Sometimes you need to check if your code reads a stripe card correctly. If so, you can specifically
assign card data to a generated card token:

```ruby
it "generates a stripe card token" do
  card_token = StripeMock.generate_card_token(last4: "9191", exp_year: 1984)

  cus = Stripe::Customer.create(source: card_token)
  card = cus.sources.data.first
  expect(card.last4).to eq("9191")
  expect(card.exp_year).to eq(1984)
end
```

## Debugging

To enable debug messages:

    StripeMock.toggle_debug(true)

This will **only last for the session**; Once you call `StripeMock.stop` or `StripeMock.stop_client`,
debug will be toggled off.

If you always want debug to be on (it's quite verbose), you should put this in a `before` block.

## Miscellaneous Features

You may have noticed that all generated Stripe ids start with `test_`. If you want to remove this:

```ruby
# Turns off test_ prefix
StripeMock.global_id_prefix = false

# Or you can set your own
StripeMock.global_id_prefix = 'my_app_'
```

## TODO

* Cover all stripe urls/methods
* Throw useful errors that emulate Stripe's requirements
  * For example: "You must supply either a card or a customer id" for `Stripe::Charge`
* Fingerprinting for other resources besides Cards

## Developing stripe-ruby-mock

[Please see this wiki page](https://github.com/rebelidealist/stripe-ruby-mock/wiki/Implementing-a-New-Behavior)

Patches are welcome and greatly appreciated! If you're contributing to fix a problem,
be sure to write tests that illustrate the problem being fixed.
This will help ensure that the problem remains fixed in future updates.

## Copyright

Copyright (c) 2013 Gilbert

See LICENSE.txt for details.
