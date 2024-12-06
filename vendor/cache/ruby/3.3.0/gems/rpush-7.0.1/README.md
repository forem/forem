[![Gem Version](https://badge.fury.io/rb/rpush.svg)](http://badge.fury.io/rb/rpush)
[![RPush Test](https://github.com/rpush/rpush/actions/workflows/test.yml/badge.svg)](https://github.com/rpush/rpush/actions/workflows/test.yml)
[![Test Coverage](https://codeclimate.com/github/rpush/rpush/badges/coverage.svg)](https://codeclimate.com/github/rpush/rpush)
[![Code Climate](https://codeclimate.com/github/rpush/rpush/badges/gpa.svg)](https://codeclimate.com/github/rpush/rpush)
[![Join the chat at https://gitter.im/rpush/rpush](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/rpush/rpush?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

<img src="https://raw.github.com/rpush/rpush/master/logo.png" align="right" width="200px" />

### Rpush. The push notification service for Ruby.

Rpush aims to be the *de facto* gem for sending push notifications in Ruby. Its core goals are ease of use, reliability and a rich feature set. Rpush provides numerous advanced features not found in others gems, giving you greater control & insight as your project grows. These are a few of the reasons why companies worldwide rely on Rpush to deliver their notifications.

#### Supported Services

  * [**Apple Push Notification Service**](#apple-push-notification-service)
    * Including Safari Push Notifications.
  * [**Firebase Cloud Messaging**](#firebase-cloud-messaging) (used to be Google Cloud Messaging)
  * [**Amazon Device Messaging**](#amazon-device-messaging)
  * [**Windows Phone Push Notification Service**](#windows-phone-notification-service)
  * [**Pushy**](#pushy)
  * [**Webpush**](#webpush)

#### Feature Highlights

* Use [**ActiveRecord**](https://github.com/rpush/rpush/wiki/Using-ActiveRecord) or [**Redis**](https://github.com/rpush/rpush/wiki/Using-Redis) for storage.
* Plugins for [**Bugsnag**](https://github.com/rpush/rpush-plugin-bugsnag),
[**Sentry**](https://github.com/rpush/rpush-plugin-sentry), [**StatsD**](https://github.com/rpush/rpush-plugin-statsd). Third party plugins: [**Prometheus Exporter**](https://github.com/equinux/rpush-plugin-prometheus-exporter). Or [write your own](https://github.com/rpush/rpush/wiki/Writing-a-Plugin).
* Seamless integration with your projects, including **Rails**.
* Run as a [daemon](https://github.com/rpush/rpush#as-a-daemon), inside a [job queue](https://github.com/rpush/rpush/wiki/Push-API), on the [command-line](https://github.com/rpush/rpush#on-the-command-line) or [embedded](https://github.com/rpush/rpush/wiki/Embedding-API) in another process.
* Scales vertically (threading) and horizontally (multiple processes).
* Designed for uptime - new apps are loaded automatically, signal `HUP` to update running apps.
* Hooks for fine-grained instrumentation and error handling ([Reflection API](https://github.com/rpush/rpush/wiki/Reflection-API)).
* Tested with **MRI**


### Getting Started

Add it to your Gemfile:

```ruby
gem 'rpush'
```

Initialize Rpush into your project. **Rails will be detected automatically.**

```sh
$ cd /path/to/project
$ bundle
$ bundle exec rpush init
```

### Create an App & Notification

#### Apple Push Notification Service

There is a choice of two modes (and one legacy mode) using certificates or using tokens:

* `Rpush::Apns2` This requires an annually renewable certificate. see https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server/establishing_a_certificate-based_connection_to_apns
* `Rpush::Apnsp8` This uses encrypted tokens and requires an encryption key id and encryption key (provide as a p8 file). (see https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server/establishing_a_token-based_connection_to_apns)
* `Rpush::Apns` There is also the original APNS (the original version using certificates with a binary underlying protocol over TCP directly rather than over Http/2).
  Apple have [announced](https://developer.apple.com/news/?id=c88acm2b) that this is not supported after March 31, 2021.

If this is your first time using the APNs, you will need to generate either SSL certificates (for Apns2 or Apns) or an Encryption Key (p8) and an Encryption Key ID (for Apnsp8). See [Generating Certificates](https://github.com/rpush/rpush/wiki/Generating-Certificates) for instructions.

##### Apnsp8

To use the p8 APNs Api:

```ruby
app = Rpush::Apnsp8::App.new
app.name = "ios_app"
app.apn_key = File.read("/path/to/sandbox.p8")
app.environment = "development" # APNs environment.
app.apn_key_id = "APN KEY ID" # This is the Encryption Key ID provided by apple
app.team_id = "TEAM ID" # the team id - e.g. ABCDE12345
app.bundle_id = "BUNDLE ID" # the unique bundle id of the app, like com.example.appname
app.connections = 1
app.save!
```

```ruby
n = Rpush::Apnsp8::Notification.new
n.app = Rpush::Apnsp8::App.find_by_name("ios_app")
n.device_token = "..." # hex string
n.alert = "hi mom!"
n.data = { foo: :bar }
n.save!
```

##### Apns2

(NB this uses the same protocol as Apnsp8, but authenticates with a certificate rather than tokens)

```ruby
app = Rpush::Apns2::App.new
app.name = "ios_app"
app.certificate = File.read("/path/to/sandbox.pem")
app.environment = "development"
app.password = "certificate password"
app.bundle_id = "BUNDLE ID" # the unique bundle id of the app, like com.example.appname
app.connections = 1
app.save!
```

```ruby
n = Rpush::Apns2::Notification.new
n.app = Rpush::Apns2::App.find_by_name("ios_app")
n.device_token = "..." # hex string
n.alert = "hi mom!"
n.data = {
  headers: { 'apns-topic': "BUNDLE ID" }, # the bundle id of the app, like com.example.appname. Not necessary if set on the app (see above)
  foo: :bar
}
n.save!
```

You should also implement the [ssl_certificate_will_expire](https://github.com/rpush/rpush/wiki/Reflection-API) reflection to monitor when your certificate is due to expire.

##### Apns (legacy protocol)

```ruby
app = Rpush::Apns::App.new
app.name = "ios_app"
app.certificate = File.read("/path/to/sandbox.pem")
app.environment = "development" # APNs environment.
app.password = "certificate password"
app.connections = 1
app.save!
```

```ruby
n = Rpush::Apns::Notification.new
n.app = Rpush::Apns::App.find_by_name("ios_app")
n.device_token = "..." # hex string
n.alert = "hi mom!"
n.data = { foo: :bar }
n.save!
```

##### Safari Push Notifications

Using one of the notifications methods above, the `url_args` attribute is available for Safari Push Notifications.

##### Environment

The app `environment` for any Apns* option is "development" for XCode installs, and "production" for app store and TestFlight. Note that for Apns2 you can now use one (production + sandbox) certificate (you don't need a separate "sandbox" or development certificate), but if you do generate a development/sandbox certificate it can only be used for "development". With Apnsp8 tokens, you can target either "development" or "production" environments.

#### Firebase Cloud Messaging

FCM and GCM are – as of writing – compatible with each other. See also [this comment](https://github.com/rpush/rpush/issues/284#issuecomment-228330206) for further references.

Please refer to the Firebase Console on where to find your `auth_key` (probably called _Server Key_ there). To verify you have the right key, use tools like [Postman](https://www.getpostman.com/), [HTTPie](https://httpie.org/), `curl` or similar before reporting a new issue. See also [this comment](https://github.com/rpush/rpush/issues/346#issuecomment-289218776).

```ruby
app = Rpush::Gcm::App.new
app.name = "android_app"
app.auth_key = "..."
app.connections = 1
app.save!
```

```ruby
n = Rpush::Gcm::Notification.new
n.app = Rpush::Gcm::App.find_by_name("android_app")
n.registration_ids = ["..."]
n.data = { message: "hi mom!" }
n.priority = 'high'        # Optional, can be either 'normal' or 'high'
n.content_available = true # Optional
# Optional notification payload. See the reference below for more keys you can use!
n.notification = { body: 'great match!',
                   title: 'Portugal vs. Denmark',
                   icon: 'myicon'
                 }
n.save!
```

FCM also requires you to respond to [Canonical IDs](https://github.com/rpush/rpush/wiki/Canonical-IDs).

Check the [FCM reference](https://firebase.google.com/docs/cloud-messaging/http-server-ref#notification-payload-support) for what keys you can use and are available to you. **Note:** Not all are yet implemented in Rpush.

#### Amazon Device Messaging

```ruby
app = Rpush::Adm::App.new
app.name = "kindle_app"
app.client_id = "..."
app.client_secret = "..."
app.connections = 1
app.save!
```

```ruby
n = Rpush::Adm::Notification.new
n.app = Rpush::Adm::App.find_by_name("kindle_app")
n.registration_ids = ["..."]
n.data = { message: "hi mom!"}
n.collapse_key = "Optional consolidationKey"
n.save!
```

For more documentation on [ADM](https://developer.amazon.com/sdk/adm.html).

#### Windows Phone Notification Service (Windows Phone 8.0 and 7.x)

Uses the older [Windows Phone 8 Toast template](https://msdn.microsoft.com/en-us/library/windows/apps/jj662938(v=vs.105).aspx)

```ruby
app = Rpush::Wpns::App.new
app.name = "windows_phone_app"
app.client_id = # Get this from your apps dashboard https://dev.windows.com
app.client_secret = # Get this from your apps dashboard https://dev.windows.com
app.connections = 1
app.save!
```

```ruby
n = Rpush::Wpns::Notification.new
n.app = Rpush::Wpns::App.find_by_name("windows_phone_app")
n.uri = "http://..."
n.data = {title:"MyApp", body:"Hello world", param:"user_param1"}
n.save!
```

#### Windows Notification Service (Windows 8.1, 10 Apps & Phone > 8.0)

Uses the more recent [Toast template](https://msdn.microsoft.com/en-us/library/windows/apps/xaml/mt631604.aspx)

The `client_id` here is the SID URL as seen [here](https://msdn.microsoft.com/en-us/library/windows/apps/hh465407.aspx#7-SIDandSecret). Do not confuse it with the `client_id` on dashboard.

You can (optionally) include a launch argument by adding a `launch` key to the notification data.

You can (optionally) include an [audio element](https://msdn.microsoft.com/en-us/library/windows/apps/xaml/br230842.aspx) by setting the sound on the notification.

```ruby
app = Rpush::Wns::App.new
app.name = "windows_phone_app"
app.client_id = YOUR_SID_URL
app.client_secret = YOUR_CLIENT_SECRET
app.connections = 1
app.save!
```

```ruby
n = Rpush::Wns::Notification.new
n.app = Rpush::Wns::App.find_by_name("windows_phone_app")
n.uri = "http://..."
n.data = {title:"MyApp", body:"Hello world", launch:"launch-argument"}
n.sound = "ms-appx:///mynotificationsound.wav"
n.save!
```

#### Windows Raw Push Notifications

Note: The data is passed as `.to_json` so only this format is supported, although raw notifications are meant to support any kind of data.
Current data structure enforces hashes and `.to_json` representation is natural presentation of it.

```ruby
n = Rpush::Wns::RawNotification.new
n.app = Rpush::Wns::App.find_by_name("windows_phone_app")
n.uri = 'http://...'
n.data = { foo: 'foo', bar: 'bar' }
n.save!
```

#### Windows Badge Push Notifications

Uses the [badge template](https://msdn.microsoft.com/en-us/library/windows/apps/xaml/br212849.aspx) and the type `wns/badge`.

```ruby
n = Rpush::Wns::BadgeNotification.new
n.app = Rpush::Wns::App.find_by_name("windows_phone_app")
n.uri = 'http://...'
n.badge = 4
n.save!
```

#### Pushy

[Pushy](https://pushy.me/) is a highly-reliable push notification gateway, based on [MQTT](https://pushy.me/support#what-is-mqtt) protocol for cross platform push notification delivery that includes web, Android, and iOS. One of its advantages is it allows for reliable notification delivery to Android devices in China where Google Cloud Messaging and Firebase Cloud Messaging are blocked and to custom hardware devices that use Android OS but are not using Google Play Services.

Note: current implementation of Pushy only supports Android devices and does not include [subscriptions](https://pushy.me/docs/android/subscribe-topics).

```ruby
app = Rpush::Pushy::App.new
app.name = "android_app"
app.api_key = YOUR_API_KEY
app.connections = 1
app.save!
```

```ruby
n = Rpush::Pushy::Notification.new
n.app = Rpush::Pushy::App.find_by_name("android_app")
n.registration_ids = ["..."]
n.data = { message: "hi mom!"}
n.time_to_live = 60 # seconds
n.save!
```

For more documentation on [Pushy](https://pushy.me/docs).

#### Webpush

[Webpush](https://tools.ietf.org/html/draft-ietf-webpush-protocol-10) is a
protocol for delivering push messages to desktop browsers. It's supported by
all major browsers (except Safari, you have to use one of the Apns transports
for that).

Using [VAPID](https://tools.ietf.org/html/draft-ietf-webpush-vapid-01), there
is no need for the sender of push notifications to register upfront with push
services (as was the case with the now legacy Mozilla or Google desktop push
providers).

Instead, you generate a pair of keys and use the public key when subscribing
users in your web app. The keys are stored along with an email address (which,
according to the spec, can be used by push service providers to contact you in
case of problems) in the `certificates` field of the Rpush Application record:

```ruby
vapid_keypair = Webpush.generate_key.to_hash
app = Rpush::Webpush::App.new
app.name = 'webpush'
app.certificate = vapid_keypair.merge(subject: 'user@example.org').to_json
app.connections = 1
app.save!
```

The `subscription` object you obtain from a subscribed browser holds an
endpoint URL and cryptographic keys. When sending a notification, simply pass
the whole subscription as sole member of the `registration_ids` collection:

```ruby
n = Rpush::Webpush::Notification.new
n.app = Rpush::App.find_by_name("webpush")
n.registration_ids = [subscription]
n.data = { message: "hi mom!" }
n.save!
```

In order to send the same message to multiple devices, create one
`Notification` per device, as passing multiple subscriptions at once as
`registration_ids` is not supported.


### Running Rpush

It is recommended to run Rpush as a separate process in most cases, though embedding and manual modes are provided for low-workload environments.

See `rpush help` for all available commands and options.

#### As a daemon

```sh
$ cd /path/to/project
$ rpush start
```

#### As a foreground process

```sh
$ cd /path/to/project
$ rpush start -f
```

#### On the command-line

```sh
$ rpush push
```

Rpush will deliver all pending notifications and then exit.

#### In a scheduled job

```ruby
Rpush.push
Rpush.apns_feedback
```

See [Push API](https://github.com/rpush/rpush/wiki/Push-API) for more details.

#### Embedded inside an existing process

```ruby
if defined?(Rails)
  ActiveSupport.on_load(:after_initialize) do
    Rpush.embed
  end
else
  Rpush.embed
end
```

Call this during startup of your application, for example, by adding it to the end of `config/rpush.rb`. See [Embedding API](https://github.com/rpush/rpush/wiki/Embedding-API) for more details.

#### Using mina

If you're using [mina](https://github.com/mina-deploy/mina), there is a gem called [mina-rpush](https://github.com/d4rky-pl/mina-rpush) which helps you control rpush.

### Cleanup

Rpush leaves delivered notifications in the database. If you do not clear them out, they will take up more and more space. This isn't great for any database, but is especially problematic if using Redis as the Rpush store. [Here](https://github.com/rpush/rpush/wiki/Using-Redis) is an example solution for cleaning up delivered notifications in Redis.

### Configuration

See [Configuration](https://github.com/rpush/rpush/wiki/Configuration) for a list of options.

### Updating Rpush

You should run `rpush init` after upgrading Rpush to check for configuration and migration changes.

### From The Wiki

### General
* [Using Redis](https://github.com/rpush/rpush/wiki/Using-Redis)
* [Using ActiveRecord](https://github.com/rpush/rpush/wiki/Using-ActiveRecord)
* [Configuration](https://github.com/rpush/rpush/wiki/Configuration)
* [Moving from Rapns](https://github.com/rpush/rpush/wiki/Moving-from-Rapns-to-Rpush)
* [Deploying to Heroku](https://github.com/rpush/rpush/wiki/Heroku)
* [Hot App Updates](https://github.com/rpush/rpush/wiki/Hot-App-Updates)
* [Signals](https://github.com/rpush/rpush/wiki/Signals)
* [Reflection API](https://github.com/rpush/rpush/wiki/Reflection-API)
* [Push API](https://github.com/rpush/rpush/wiki/Push-API)
* [Embedding API](https://github.com/rpush/rpush/wiki/Embedding-API)
* [Writing a Plugin](https://github.com/rpush/rpush/wiki/Writing-a-Plugin)
* [Implementing your own storage backend](https://github.com/rpush/rpush/wiki/Implementing-your-own-storage-backend)
* [Upgrading from 2.x to 3.0](https://github.com/rpush/rpush/wiki/Upgrading-from-version-2.x-to-3.0)

### Apple Push Notification Service
* [Generating Certificates](https://github.com/rpush/rpush/wiki/Generating-Certificates)
* [Advanced APNs Features](https://github.com/rpush/rpush/wiki/Advanced-APNs-Features)
* [APNs Delivery Failure Handling](https://github.com/rpush/rpush/wiki/APNs-Delivery-Failure-Handling)
* [Why open multiple connections to the APNs?](https://github.com/rpush/rpush/wiki/Why-open-multiple-connections-to-the-APNs%3F)
* [Silent failures might be dropped connections](https://github.com/rpush/rpush/wiki/Dropped-connections)

### Firebase Cloud Messaging
* [Notification Options](https://github.com/rpush/rpush/wiki/GCM-Notification-Options)
* [Canonical IDs](https://github.com/rpush/rpush/wiki/Canonical-IDs)
* [Delivery Failures & Retries](https://github.com/rpush/rpush/wiki/Delivery-Failures-&-Retries)

### Contributing

#### Running Tests

Rpush uses [Appraisal](https://github.com/thoughtbot/appraisal) to run tests against multiple versions of Ruby on Rails. This helps making sure that Rpush performs correctly with multiple Rails versions.

Rpush also uses RSpec for its tests.

##### Bootstrapping your test suite:

First, we need to setup a test database, `rpush_test`.

E.g. (postgres): `psql -c 'create database rpush_test;' -U postgres >/dev/null`

```
bundle install
bundle exec appraisal install
```
This will install all the required gems that requires to test against each version of Rails, which defined in `gemfiles/*.gemfile`.

##### To run a full test suite:

```
bundle exec appraisal rake
```
This will run RSpec against all versions of Rails.

##### To run a single test

You need to specify a `BUNDLE_GEMFILE` pointing to the gemfile before running the normal test command:

```
BUNDLE_GEMFILE=gemfiles/rails_5.2.gemfile rspec spec/unit/apns_feedback_spec.rb
```

##### Multiple database adapter support

When running specs, please note that the ActiveRecord adapter can be changed by setting the `ADAPTER` environment variable. For example: `ADAPTER=postgresql rake`.

Available adapters for testing are `postgresql`, `jdbcpostgresql`, `mysql2`, `jdbcmysql`, `jdbch2`, and `sqlite3`.

Note that the database username is changed at runtime to be the currently logged in user's name. So if you're testing
with mysql and you're using a user named 'bob', you will need to grant a mysql user 'bob' access to the 'rpush_test'
mysql database.

To switch between ActiveRecord and Redis, set the `CLIENT` environment variable to either `active_record` or `redis`.
