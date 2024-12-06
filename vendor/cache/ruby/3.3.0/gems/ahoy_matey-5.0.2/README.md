# Ahoy

:fire: Simple, powerful, first-party analytics for Rails

Track visits and events in Ruby, JavaScript, and native apps. Data is stored in your database by default, and you can customize it for any data store as you grow.

**Ahoy 5.0 was recently released** - see [how to upgrade](#upgrading)

:postbox: Check out [Ahoy Email](https://github.com/ankane/ahoy_email) for emails and [Field Test](https://github.com/ankane/field_test) for A/B testing

:tangerine: Battle-tested at [Instacart](https://www.instacart.com/opensource)

[![Build Status](https://github.com/ankane/ahoy/workflows/build/badge.svg?branch=master)](https://github.com/ankane/ahoy/actions)

## Installation

Add this line to your application’s Gemfile:

```ruby
gem "ahoy_matey"
```

And run:

```sh
bundle install
rails generate ahoy:install
rails db:migrate
```

Restart your web server, open a page in your browser, and a visit will be created :tada:

Track your first event from a controller with:

```ruby
ahoy.track "My first event", language: "Ruby"
```

### JavaScript, Native Apps, & AMP

Enable the API in `config/initializers/ahoy.rb`:

```ruby
Ahoy.api = true
```

And restart your web server.

### JavaScript

For Importmap (Rails 7 default), add to `config/importmap.rb`:

```ruby
pin "ahoy", to: "ahoy.js"
```

And add to `app/javascript/application.js`:

```javascript
import "ahoy"
```

For Webpacker (Rails 6 default), run:

```sh
yarn add ahoy.js
```

And add to `app/javascript/packs/application.js`:

```javascript
import ahoy from "ahoy.js"
```

For Sprockets, add to `app/assets/javascripts/application.js`:

```javascript
//= require ahoy
```

Track an event with:

```javascript
ahoy.track("My second event", {language: "JavaScript"});
```

### Native Apps

Check out [Ahoy iOS](https://github.com/namolnad/ahoy-ios) and [Ahoy Android](https://github.com/instacart/ahoy-android).

### Geocoding Setup

To enable geocoding, see the [Geocoding section](#geocoding).

### GDPR Compliance

Ahoy provides a number of options to help with GDPR compliance. See the [GDPR section](#gdpr-compliance-1) for more info.

## How It Works

### Visits

When someone visits your website, Ahoy creates a visit with lots of useful information.

- **traffic source** - referrer, referring domain, landing page
- **location** - country, region, city, latitude, longitude
- **technology** - browser, OS, device type
- **utm parameters** - source, medium, term, content, campaign

Use the `current_visit` method to access it.

Prevent certain Rails actions from creating visits with:

```ruby
skip_before_action :track_ahoy_visit
```

This is typically useful for APIs. If your entire Rails app is an API, you can use:

```ruby
Ahoy.api_only = true
```

You can also defer visit tracking to JavaScript. This is useful for preventing bots (that aren’t detected by their user agent) and users with cookies disabled from creating a new visit on each request. `:when_needed` will create visits server-side only when needed by events, and `false` will disable server-side creation completely, discarding events without a visit.

```ruby
Ahoy.server_side_visits = :when_needed
```

### Events

Each event has a `name` and `properties`. There are several ways to track events.

#### Ruby

```ruby
ahoy.track "Viewed book", title: "Hot, Flat, and Crowded"
```

Track actions automatically with:

```ruby
class ApplicationController < ActionController::Base
  after_action :track_action

  protected

  def track_action
    ahoy.track "Ran action", request.path_parameters
  end
end
```

#### JavaScript

```javascript
ahoy.track("Viewed book", {title: "The World is Flat"});
```

See [Ahoy.js](https://github.com/ankane/ahoy.js) for a complete list of features.

#### Native Apps

See the docs for [Ahoy iOS](https://github.com/namolnad/ahoy-ios) and [Ahoy Android](https://github.com/instacart/ahoy-android).

#### AMP

```erb
<head>
  <script async custom-element="amp-analytics" src="https://cdn.ampproject.org/v0/amp-analytics-0.1.js"></script>
</head>
<body>
  <%= amp_event "Viewed article", title: "Analytics with Rails" %>
</body>
```

### Associated Models

Say we want to associate orders with visits. Just add `visitable` to the model.

```ruby
class Order < ApplicationRecord
  visitable :ahoy_visit
end
```

When a visitor places an order, the `ahoy_visit_id` column is automatically set :tada:

See where orders are coming from with simple joins:

```ruby
Order.joins(:ahoy_visit).group("referring_domain").count
Order.joins(:ahoy_visit).group("city").count
Order.joins(:ahoy_visit).group("device_type").count
```

Here’s what the migration to add the `ahoy_visit_id` column should look like:

```ruby
class AddAhoyVisitToOrders < ActiveRecord::Migration[7.0]
  def change
    add_reference :orders, :ahoy_visit
  end
end
```

Customize the column with:

```ruby
visitable :sign_up_visit
```

### Users

Ahoy automatically attaches the `current_user` to the visit. With [Devise](https://github.com/heartcombo/devise), it attaches the user even if they sign in after the visit starts.

With other authentication frameworks, add this to the end of your sign in method:

```ruby
ahoy.authenticate(user)
```

To see the visits for a given user, create an association:

```ruby
class User < ApplicationRecord
  has_many :visits, class_name: "Ahoy::Visit"
end
```

And use:

```ruby
User.find(123).visits
```

#### Custom User Method

Use a method besides `current_user`

```ruby
Ahoy.user_method = :true_user
```

or use a proc

```ruby
Ahoy.user_method = ->(controller) { controller.true_user }
```

#### Doorkeeper

To attach the user with [Doorkeeper](https://github.com/doorkeeper-gem/doorkeeper), be sure you have a `current_resource_owner` method in `ApplicationController`.

```ruby
class ApplicationController < ActionController::Base
  private

  def current_resource_owner
    User.find(doorkeeper_token.resource_owner_id) if doorkeeper_token
  end
end
```

### Exclusions

Bots are excluded from tracking by default. To include them, use:

```ruby
Ahoy.track_bots = true
```

Add your own rules with:

```ruby
Ahoy.exclude_method = lambda do |controller, request|
  request.ip == "192.168.1.1"
end
```

### Visit Duration

By default, a new visit is created after 4 hours of inactivity. Change this with:

```ruby
Ahoy.visit_duration = 30.minutes
```

### Visitor Duration

By default, a new `visitor_token` is generated after 2 years. Change this with:

```ruby
Ahoy.visitor_duration = 30.days
```

### Cookies

To track visits across multiple subdomains, use:

```ruby
Ahoy.cookie_domain = :all
```

Set other [cookie options](https://api.rubyonrails.org/classes/ActionDispatch/Cookies.html) with:

```ruby
Ahoy.cookie_options = {same_site: :lax}
```

You can also [disable cookies](#anonymity-sets--cookies)

### Token Generation

Ahoy uses random UUIDs for visit and visitor tokens by default, but you can use your own generator like [ULID](https://github.com/rafaelsales/ulid).

```ruby
Ahoy.token_generator = -> { ULID.generate }
```

### Throttling

You can use [Rack::Attack](https://github.com/rack/rack-attack) to throttle requests to the API.

```ruby
class Rack::Attack
  throttle("ahoy/ip", limit: 20, period: 1.minute) do |req|
    if req.path.start_with?("/ahoy/")
      req.ip
    end
  end
end
```

### Exceptions

Exceptions are rescued so analytics do not break your app. Ahoy uses [Safely](https://github.com/ankane/safely) to try to report them to a service by default. To customize this, use:

```ruby
Safely.report_exception_method = ->(e) { Rollbar.error(e) }
```

## Geocoding

Ahoy uses [Geocoder](https://github.com/alexreisner/geocoder) for geocoding. We recommend configuring [local geocoding](#local-geocoding) or [load balancer geocoding](#load-balancer-geocoding) so IP addresses are not sent to a 3rd party service. If you do use a 3rd party service and adhere to GDPR, be sure to add it to your subprocessor list. If Ahoy is configured to [mask IPs](#ip-masking), the masked IP is used (this can reduce accuracy but is better for privacy).

To enable geocoding, add this line to your application’s Gemfile:

```ruby
gem "geocoder"
```

And update `config/initializers/ahoy.rb`:

```ruby
Ahoy.geocode = true
```

Geocoding is performed in a background job so it doesn’t slow down web requests. The default job queue is `:ahoy`. Change this with:

```ruby
Ahoy.job_queue = :low_priority
```

### Local Geocoding

For privacy and performance, we recommend geocoding locally.

For city-level geocoding, download the [GeoLite2 City database](https://dev.maxmind.com/geoip/geolite2-free-geolocation-data).

Add this line to your application’s Gemfile:

```ruby
gem "maxminddb"
```

And create `config/initializers/geocoder.rb` with:

```ruby
Geocoder.configure(
  ip_lookup: :geoip2,
  geoip2: {
    file: "path/to/GeoLite2-City.mmdb"
  }
)
```

For country-level geocoding, install the `geoip-database` package. It’s preinstalled on Heroku. For Ubuntu, use:

```sh
sudo apt-get install geoip-database
```

Add this line to your application’s Gemfile:

```ruby
gem "geoip"
```

And create `config/initializers/geocoder.rb` with:

```ruby
Geocoder.configure(
  ip_lookup: :maxmind_local,
  maxmind_local: {
    file: "/usr/share/GeoIP/GeoIP.dat",
    package: :country
  }
)
```

### Load Balancer Geocoding

Some load balancers can add geocoding information to request headers.

- [nginx](https://nginx.org/en/docs/http/ngx_http_geoip_module.html)
- [Google Cloud](https://cloud.google.com/load-balancing/docs/custom-headers)
- [Cloudflare](https://support.cloudflare.com/hc/en-us/articles/200168236-Configuring-Cloudflare-IP-Geolocation)

Update `config/initializers/ahoy.rb` with:

```ruby
Ahoy.geocode = false

class Ahoy::Store < Ahoy::DatabaseStore
  def track_visit(data)
    data[:country] = request.headers["<country-header>"]
    data[:region] = request.headers["<region-header>"]
    data[:city] = request.headers["<city-header>"]
    super(data)
  end
end
```

## GDPR Compliance

Ahoy provides a number of options to help with [GDPR compliance](https://en.wikipedia.org/wiki/General_Data_Protection_Regulation).

Update `config/initializers/ahoy.rb` with:

```ruby
class Ahoy::Store < Ahoy::DatabaseStore
  def authenticate(data)
    # disables automatic linking of visits and users
  end
end

Ahoy.mask_ips = true
Ahoy.cookies = :none
```

This:

- Masks IP addresses
- Switches from cookies to anonymity sets
- Disables automatic linking of visits and users

If you use JavaScript tracking, also set:

```javascript
ahoy.configure({cookies: false});
```

### IP Masking

Ahoy can mask IPs with the same approach [Google Analytics uses for IP anonymization](https://support.google.com/analytics/answer/2763052). This means:

- For IPv4, the last octet is set to 0 (`8.8.4.4` becomes `8.8.4.0`)
- For IPv6, the last 80 bits are set to zeros (`2001:4860:4860:0:0:0:0:8844` becomes `2001:4860:4860::`)

```ruby
Ahoy.mask_ips = true
```

IPs are masked before geolocation is performed.

To mask previously collected IPs, use:

```ruby
Ahoy::Visit.find_each do |visit|
  visit.update_column :ip, Ahoy.mask_ip(visit.ip)
end
```

### Anonymity Sets & Cookies

Ahoy can switch from cookies to [anonymity sets](https://privacypatterns.org/patterns/Anonymity-set). Instead of cookies, visitors with the same IP mask and user agent are grouped together in an anonymity set.

```ruby
Ahoy.cookies = :none
```

Note: If Ahoy was installed before v5, [add an index](#50) before making this change.

Previously set cookies are automatically deleted. If you use JavaScript tracking, also set:

```javascript
ahoy.configure({cookies: false});
```

## Data Retention

Data should only be retained for as long as it’s needed. Delete older data with:

```ruby
Ahoy::Visit.where("started_at < ?", 2.years.ago).find_in_batches do |visits|
  visit_ids = visits.map(&:id)
  Ahoy::Event.where(visit_id: visit_ids).delete_all
  Ahoy::Visit.where(id: visit_ids).delete_all
end
```

You can use [Rollup](https://github.com/ankane/rollup) to aggregate important data before you do.

```ruby
Ahoy::Visit.rollup("Visits", interval: "hour")
```

Delete data for a specific user with:

```ruby
user_id = 123
visit_ids = Ahoy::Visit.where(user_id: user_id).pluck(:id)
Ahoy::Event.where(visit_id: visit_ids).delete_all
Ahoy::Visit.where(id: visit_ids).delete_all
Ahoy::Event.where(user_id: user_id).delete_all
```

## Development

Ahoy is built with developers in mind. You can run the following code in your browser’s console.

Force a new visit

```javascript
ahoy.reset(); // then reload the page
```

Log messages

```javascript
ahoy.debug();
```

Turn off logging

```javascript
ahoy.debug(false);
```

Debug API requests in Ruby

```ruby
Ahoy.quiet = false
```

## Data Stores

Data tracked by Ahoy is sent to your data store. Ahoy ships with a data store that uses your Rails database by default. You can find it in `config/initializers/ahoy.rb`:

```ruby
class Ahoy::Store < Ahoy::DatabaseStore
end
```

There are four events data stores can subscribe to:

```ruby
class Ahoy::Store < Ahoy::BaseStore
  def track_visit(data)
    # new visit
  end

  def track_event(data)
    # new event
  end

  def geocode(data)
    # visit geocoded
  end

  def authenticate(data)
    # user authenticates
  end
end
```

Data stores are designed to be highly customizable so you can scale as you grow. Check out [examples](docs/Data-Store-Examples.md) for Kafka, RabbitMQ, Fluentd, NATS, NSQ, and Amazon Kinesis Firehose.

### Track Additional Data

```ruby
class Ahoy::Store < Ahoy::DatabaseStore
  def track_visit(data)
    data[:accept_language] = request.headers["Accept-Language"]
    super(data)
  end
end
```

Two useful methods you can use are `request` and `controller`.

You can pass additional visit data from JavaScript with:

```javascript
ahoy.configure({visitParams: {referral_code: 123}});
```

And use:

```ruby
class Ahoy::Store < Ahoy::DatabaseStore
  def track_visit(data)
    data[:referral_code] = request.parameters[:referral_code]
    super(data)
  end
end
```

### Use Different Models

```ruby
class Ahoy::Store < Ahoy::DatabaseStore
  def visit_model
    MyVisit
  end

  def event_model
    MyEvent
  end
end
```

## Explore the Data

[Blazer](https://github.com/ankane/blazer) is a great tool for exploring your data.

With Active Record, you can do:

```ruby
Ahoy::Visit.group(:search_keyword).count
Ahoy::Visit.group(:country).count
Ahoy::Visit.group(:referring_domain).count
```

[Chartkick](https://www.chartkick.com/) and [Groupdate](https://github.com/ankane/groupdate) make it easy to visualize the data.

```erb
<%= line_chart Ahoy::Visit.group_by_day(:started_at).count %>
```

### Querying Events

Ahoy provides a few methods on the event model to make querying easier.

To query on both name and properties, you can use:

```ruby
Ahoy::Event.where_event("Viewed product", product_id: 123).count
```

Or just query properties with:

```ruby
Ahoy::Event.where_props(product_id: 123, category: "Books").count
```

Group by properties with:

```ruby
Ahoy::Event.group_prop(:product_id, :category).count
```

Note: MySQL and MariaDB always return string keys (including `"null"` for `nil`) for `group_prop`.

### Funnels

It’s easy to create funnels.

```ruby
viewed_store_ids = Ahoy::Event.where(name: "Viewed store").distinct.pluck(:user_id)
added_item_ids = Ahoy::Event.where(user_id: viewed_store_ids, name: "Added item to cart").distinct.pluck(:user_id)
viewed_checkout_ids = Ahoy::Event.where(user_id: added_item_ids, name: "Viewed checkout").distinct.pluck(:user_id)
```

The same approach also works with visitor tokens.

### Rollups

Improve query performance by pre-aggregating data with [Rollup](https://github.com/ankane/rollup).

```ruby
Ahoy::Event.where(name: "Viewed store").rollup("Store views")
```

This is only needed if you have a lot of data.

### Forecasting

To forecast future visits and events, check out [Prophet](https://github.com/ankane/prophet).

```ruby
daily_visits = Ahoy::Visit.group_by_day(:started_at).count # uses Groupdate
Prophet.forecast(daily_visits)
```

### Anomaly Detection

To detect anomalies in visits and events, check out [AnomalyDetection.rb](https://github.com/ankane/AnomalyDetection.rb).

```ruby
daily_visits = Ahoy::Visit.group_by_day(:started_at).count # uses Groupdate
AnomalyDetection.detect(daily_visits, period: 7)
```

### Breakout Detection

To detect breakouts in visits and events, check out [Breakout](https://github.com/ankane/breakout).

```ruby
daily_visits = Ahoy::Visit.group_by_day(:started_at).count # uses Groupdate
Breakout.detect(daily_visits)
```

### Recommendations

To make recommendations based on events, check out [Disco](https://github.com/ankane/disco#ahoy).

## Tutorials

- [Tracking Metrics with Ahoy and Blazer](https://gorails.com/episodes/internal-metrics-with-ahoy-and-blazer)

## API Spec

### Visits

Generate visit and visitor tokens as [UUIDs](https://en.wikipedia.org/wiki/Universally_unique_identifier), and include these values in the `Ahoy-Visit` and `Ahoy-Visitor` headers with all requests.

Send a `POST` request to `/ahoy/visits` with `Content-Type: application/json` and a body like:

```json
{
  "visit_token": "<visit-token>",
  "visitor_token": "<visitor-token>",
  "platform": "iOS",
  "app_version": "1.0.0",
  "os_version": "11.2.6"
}
```

After 4 hours of inactivity, create another visit (use the same visitor token).

### Events

Send a `POST` request to `/ahoy/events` with `Content-Type: application/json` and a body like:

```json
{
  "visit_token": "<visit-token>",
  "visitor_token": "<visitor-token>",
  "events": [
    {
      "id": "<optional-random-id>",
      "name": "Viewed item",
      "properties": {
        "item_id": 123
      },
      "time": "2018-01-01T00:00:00-07:00"
    }
  ]
}
```

## Upgrading

### 5.0

Visits now expire with anonymity sets. If using `Ahoy.cookies = false`, a new index is needed.

For Active Record, create a migration with:

```ruby
add_index :ahoy_visits, [:visitor_token, :started_at]
```

For Mongoid, set:

```ruby
class Ahoy::Visit
  index({visitor_token: 1, started_at: 1})
end
```

Create the index before upgrading, and set:

```ruby
Ahoy.cookies = :none
```

## History

View the [changelog](https://github.com/ankane/ahoy/blob/master/CHANGELOG.md)

## Contributing

Everyone is encouraged to help improve this project. Here are a few ways you can help:

- [Report bugs](https://github.com/ankane/ahoy/issues)
- Fix bugs and [submit pull requests](https://github.com/ankane/ahoy/pulls)
- Write, clarify, or fix documentation
- Suggest or add new features

To get started with development:

```sh
git clone https://github.com/ankane/ahoy.git
cd ahoy
bundle install
bundle exec rake test
```

To test different adapters, use:

```sh
ADAPTER=postgresql bundle exec rake test
ADAPTER=mysql2 bundle exec rake test
ADAPTER=mongoid bundle exec rake test
```
