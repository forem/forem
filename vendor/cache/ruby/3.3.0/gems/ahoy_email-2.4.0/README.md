# Ahoy Email

First-party email analytics for Rails

:fire: For web and native app analytics, check out [Ahoy](https://github.com/ankane/ahoy)

:bullettrain_side: To manage email subscriptions, check out [Mailkick](https://github.com/ankane/mailkick)

[![Build Status](https://github.com/ankane/ahoy_email/actions/workflows/build.yml/badge.svg)](https://github.com/ankane/ahoy_email/actions)

## Installation

Add this line to your application’s Gemfile:

```ruby
gem "ahoy_email"
```

## Getting Started

There are three main features, which can be used independently:

- [Message history](#message-history)
- [UTM tagging](#utm-tagging)
- [Click analytics](#click-analytics)

## Message History

To encrypt email addresses with Lockbox, install [Lockbox](https://github.com/ankane/lockbox) and [Blind Index](https://github.com/ankane/blind_index) and run:

```sh
rails generate ahoy:messages --encryption=lockbox
rails db:migrate
```

To use Active Record encryption, run:

```sh
rails generate ahoy:messages --encryption=activerecord
rails db:migrate
```

If you prefer not to encrypt data, run:

```sh
rails generate ahoy:messages --encryption=none
rails db:migrate
```

Then, add to mailers:

```ruby
class CouponMailer < ApplicationMailer
  has_history
end
```

Use the `Ahoy::Message` model to query messages:

```ruby
Ahoy::Message.last
```

Use only and except to limit actions

```ruby
class CouponMailer < ApplicationMailer
  has_history only: [:welcome]
end
```

To store history for all mailers, create `config/initializers/ahoy_email.rb` with:

```ruby
AhoyEmail.default_options[:message] = true
```

### Users

By default, Ahoy Email tries `@user` then `params[:user]` then `User.find_by(email: message.to)` to find the user. You can pass a specific user with:

```ruby
class CouponMailer < ApplicationMailer
  has_history user: -> { params[:some_user] }
end
```

The user association is [polymorphic](https://railscasts.com/episodes/154-polymorphic-association), so use it with any model.

To get all messages sent to a user, add an association:

```ruby
class User < ApplicationRecord
  has_many :messages, class_name: "Ahoy::Message", as: :user
end
```

And run:

```ruby
user.messages
```

### Extra Data

Add extra data to messages. Create a migration like:

```ruby
class AddCouponIdToAhoyMessages < ActiveRecord::Migration[8.0]
  def change
    add_column :ahoy_messages, :coupon_id, :integer
  end
end
```

And use:

```ruby
class CouponMailer < ApplicationMailer
  has_history extra: {coupon_id: 1}
end
```

You can use a proc as well.

```ruby
class CouponMailer < ApplicationMailer
  has_history extra: -> { {coupon_id: params[:coupon].id} }
end
```

### Options

Set global options

```ruby
AhoyEmail.default_options[:user] = -> { params[:admin] }
```

Use a different model

```ruby
AhoyEmail.message_model = -> { UserMessage }
```

Or fully customize how messages are tracked

```ruby
AhoyEmail.track_method = lambda do |data|
  # your code
end
```

### Data Retention

Delete older data with:

```ruby
Ahoy::Message.where("sent_at < ?", 1.year.ago).in_batches.delete_all
```

Delete data for a specific user with:

```ruby
Ahoy::Message.where(user_id: 1, user_type: "User").in_batches.delete_all
```

## UTM Tagging

Use UTM tagging to attribute visits or conversions to an email campaign. Add UTM parameters to links with:

```ruby
class CouponMailer < ApplicationMailer
  utm_params
end
```

The defaults are:

- `utm_medium` - `email`
- `utm_source` - the mailer name like `coupon_mailer`
- `utm_campaign` - the mailer action like `offer`

You can customize them with:

```ruby
class CouponMailer < ApplicationMailer
  utm_params utm_campaign: -> { "coupon#{params[:coupon].id}" }
end
```

Use only and except to limit actions

```ruby
class CouponMailer < ApplicationMailer
  utm_params only: [:welcome]
end
```

Skip specific links with:

```erb
<%= link_to "Go", some_url, data: {skip_utm_params: true} %>
```

## Click Analytics

You can track click-through rate to see how well campaigns are performing. Stats can be stored in your database, Redis, or any other data store.

#### Database

Run:

```sh
rails generate ahoy:clicks
rails db:migrate
```

And create `config/initializers/ahoy_email.rb` with:

```ruby
AhoyEmail.subscribers << AhoyEmail::DatabaseSubscriber
AhoyEmail.api = true
```

#### Redis

Add this line to your application’s Gemfile:

```ruby
gem "redis"
```

And create `config/initializers/ahoy_email.rb` with:

```ruby
# pass your Redis client if you already have one
AhoyEmail.subscribers << AhoyEmail::RedisSubscriber.new(redis: Redis.new)
AhoyEmail.api = true
```

#### Other

Create `config/initializers/ahoy_email.rb` with:

```ruby
class EmailSubscriber
  def track_send(data)
    # your code
  end

  def track_click(data)
    # your code
  end

  def stats(campaign)
    # optional, for AhoyEmail.stats
  end
end

AhoyEmail.subscribers << EmailSubscriber
AhoyEmail.api = true
````

### Usage

Add to mailers you want to track

```ruby
class CouponMailer < ApplicationMailer
  track_clicks campaign: "my-campaign"
end
```

If storing stats in the database, the mailer should also use `has_history`

Use only and except to limit actions

```ruby
class CouponMailer < ApplicationMailer
  track_clicks campaign: "my-campaign", only: [:welcome]
end
```

Or make it conditional

```ruby
class CouponMailer < ApplicationMailer
  track_clicks campaign: "my-campaign", if: -> { params[:user].opted_in? }
end
```

You can also use a proc

```ruby
class CouponMailer < ApplicationMailer
  track_clicks campaign: -> { "coupon-#{action_name}" }
end
```

Skip specific links with:

```erb
<%= link_to "Go", some_url, data: {skip_click: true} %>
```

By default, unsubscribe links are excluded. To change this, use:

```ruby
AhoyEmail.default_options[:unsubscribe_links] = true
```

You can specify the domain to use with:

```ruby
AhoyEmail.default_options[:url_options] = {host: "mydomain.com"}
```

### Stats

Get stats for a campaign

```ruby
AhoyEmail.stats("my-campaign")
```

## HTML Parsing

By default, Nokogiri’s default HTML parser is used to rewrite links for UTM tagging and click analytics. This currently uses HTML4, which [only allows inline elements inside links](https://github.com/sparklemotion/nokogiri/issues/1876#issuecomment-468276937).

To use HTML5 parsing, create `config/initializers/ahoy_email.rb` with:

```ruby
AhoyEmail.default_options[:html5] = true
```

## History

View the [changelog](https://github.com/ankane/ahoy_email/blob/master/CHANGELOG.md)

## Contributing

Everyone is encouraged to help improve this project. Here are a few ways you can help:

- [Report bugs](https://github.com/ankane/ahoy_email/issues)
- Fix bugs and [submit pull requests](https://github.com/ankane/ahoy_email/pulls)
- Write, clarify, or fix documentation
- Suggest or add new features

To get started with development:

```sh
git clone https://github.com/ankane/ahoy_email.git
cd ahoy_email
bundle install
bundle exec rake test
```
