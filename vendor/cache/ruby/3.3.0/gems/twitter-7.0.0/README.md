# The Twitter Ruby Gem

[![Gem Version](https://badge.fury.io/rb/twitter.svg)][gem]
[![Build Status](https://travis-ci.org/sferik/twitter.svg?branch=master)][travis]
[![Maintainability](https://api.codeclimate.com/v1/badges/09362621ad91e8f599b3/maintainability)][maintainability]
[![Coverage Status](https://coveralls.io/repos/github/sferik/twitter/badge.svg?branch=master)][coveralls]
[![Inline docs](http://inch-ci.org/github/sferik/twitter.svg?style=shields)][inchpages]

[gem]: https://rubygems.org/gems/twitter
[travis]: https://travis-ci.org/sferik/twitter
[maintainability]: https://codeclimate.com/github/sferik/twitter/maintainability
[coveralls]: https://coveralls.io/r/sferik/twitter
[inchpages]: http://inch-ci.org/github/sferik/twitter

A Ruby interface to the Twitter API.

## Installation
    gem install twitter

## CLI
Looking for the Twitter command-line interface? It was [removed][] from this
gem in version 0.5.0 and now exists as a [separate project][t].

[removed]: https://github.com/sferik/twitter/commit/dd2445e3e2c97f38b28a3f32ea902536b3897adf
[t]: https://github.com/sferik/t

## Documentation
[http://rdoc.info/gems/twitter][documentation]

[documentation]: http://rdoc.info/gems/twitter

## Examples
[https://github.com/sferik/twitter/tree/master/examples][examples]

[examples]: https://github.com/sferik/twitter/tree/master/examples

## Announcements
You should [follow @gem][follow] on Twitter for announcements and updates about
this library.

[follow]: https://twitter.com/gem

## Mailing List
Please direct questions about this library to the [mailing list].

[mailing list]: https://groups.google.com/group/twitter-ruby-gem

## Apps Wiki
Does your project or organization use this gem? Add it to the [apps
wiki][apps]!

[apps]: https://github.com/sferik/twitter/wiki/apps

## Configuration
Twitter API v1.1 requires you to authenticate via OAuth, so you'll need to
[register your application with Twitter][register]. Once you've registered an
application, make sure to set the correct access level, otherwise you may see
the error:

[register]: https://apps.twitter.com/

    Read-only application cannot POST

Your new application will be assigned a consumer key/secret pair and you will
be assigned an OAuth access token/secret pair for that application. You'll need
to configure these values before you make a request or else you'll get the
error:

    Bad Authentication data

You can pass configuration options as a block to `Twitter::REST::Client.new`.

```ruby
client = Twitter::REST::Client.new do |config|
  config.consumer_key        = "YOUR_CONSUMER_KEY"
  config.consumer_secret     = "YOUR_CONSUMER_SECRET"
  config.access_token        = "YOUR_ACCESS_TOKEN"
  config.access_token_secret = "YOUR_ACCESS_SECRET"
end
```

## Usage Examples
After configuring a `client`, you can do the following things.

**Tweet (as the authenticated user)**

```ruby
client.update("I'm tweeting with @gem!")
```
**Follow a user (by screen name or user ID)**

```ruby
client.follow("gem")
client.follow(213747670)
```
**Fetch a user (by screen name or user ID)**

```ruby
client.user("gem")
client.user(213747670)
```
**Fetch a cursored list of followers with profile details (by screen name or user ID, or by implicit authenticated user)**

```ruby
client.followers("gem")
client.followers(213747670)
client.followers
```
**Fetch a cursored list of friends with profile details (by screen name or user ID, or by implicit authenticated user)**

```ruby
client.friends("gem")
client.friends(213747670)
client.friends
```

**Fetch the timeline of Tweets by a user**

```ruby
client.user_timeline("gem")
client.user_timeline(213747670)
```
**Fetch the timeline of Tweets from the authenticated user's home page**

```ruby
client.home_timeline
```
**Fetch the timeline of Tweets mentioning the authenticated user**

```ruby
client.mentions_timeline
```
**Fetch a particular Tweet by ID**

```ruby
client.status(27558893223)
```
**Collect the three most recent marriage proposals to @justinbieber**

```ruby
client.search("to:justinbieber marry me", result_type: "recent").take(3).collect do |tweet|
  "#{tweet.user.screen_name}: #{tweet.text}"
end
```
**Find a Japanese-language Tweet tagged #ruby (excluding retweets)**

```ruby
client.search("#ruby -rt", lang: "ja").first.text
```
For more usage examples, please see the full [documentation][].

## Streaming
Site Streams are restricted to whitelisted accounts. To apply for access,
[follow the steps in the Site Streams documentation][site-streams]. [User
Streams][user-streams] do not require prior approval.

[site-streams]: https://dev.twitter.com/streaming/sitestreams#applyingforaccess
[user-streams]: https://dev.twitter.com/streaming/userstreams

**Configuration works just like `Twitter::REST::Client`**

```ruby
client = Twitter::Streaming::Client.new do |config|
  config.consumer_key        = "YOUR_CONSUMER_KEY"
  config.consumer_secret     = "YOUR_CONSUMER_SECRET"
  config.access_token        = "YOUR_ACCESS_TOKEN"
  config.access_token_secret = "YOUR_ACCESS_SECRET"
end
```

**Stream a random sample of all tweets**

```ruby
client.sample do |object|
  puts object.text if object.is_a?(Twitter::Tweet)
end
```

**Stream mentions of coffee or tea**

```ruby
topics = ["coffee", "tea"]
client.filter(track: topics.join(",")) do |object|
  puts object.text if object.is_a?(Twitter::Tweet)
end
```

**Stream tweets, events, and direct messages for the authenticated user**

```ruby
client.user do |object|
  case object
  when Twitter::Tweet
    puts "It's a tweet!"
  when Twitter::DirectMessage
    puts "It's a direct message!"
  when Twitter::Streaming::StallWarning
    warn "Falling behind!"
  end
end
```

An `object` may be one of the following:
* `Twitter::Tweet`
* `Twitter::DirectMessage`
* `Twitter::Streaming::DeletedTweet`
* `Twitter::Streaming::Event`
* `Twitter::Streaming::FriendList`
* `Twitter::Streaming::StallWarning`

## Ads

We recommend using the [Twitter Ads SDK for Ruby][ads] to interact with the Twitter Ads API.

[ads]: http://twitterdev.github.io/twitter-ruby-ads-sdk/

## Object Graph
![Entity-relationship diagram][erd]

[erd]: https://cdn.rawgit.com/sferik/twitter/master/etc/erd.svg "Entity-relationship diagram"

This entity-relationship diagram is generated programatically. If you add or
remove any Twitter objects, please regenerate the ERD with the following
command:

    bundle exec rake erd

## Supported Ruby Versions
This library aims to support and is [tested against][travis] the following Ruby
versions:

* Ruby 2.4
* Ruby 2.5
* Ruby 2.6
* Ruby 2.7

If something doesn't work on one of these versions, it's a bug.

This library may inadvertently work (or seem to work) on other Ruby versions,
however support will only be provided for the versions listed above.

If you would like this library to support another Ruby version or
implementation, you may volunteer to be a maintainer. Being a maintainer
entails making sure all tests run and pass on that implementation. When
something breaks on your implementation, you will be responsible for providing
patches in a timely fashion. If critical issues for a particular implementation
exist at the time of a major release, support for that Ruby version may be
dropped.

## Versioning
This library aims to adhere to [Semantic Versioning 2.0.0][semver]. Violations
of this scheme should be reported as bugs. Specifically, if a minor or patch
version is released that breaks backward compatibility, that version should be
immediately yanked and/or a new version should be immediately released that
restores compatibility. Breaking changes to the public API will only be
introduced with new major versions. As a result of this policy, you can (and
should) specify a dependency on this gem using the [Pessimistic Version
Constraint][pvc] with two digits of precision. For example:

    spec.add_dependency 'twitter', '~> 6.0'

[semver]: http://semver.org/
[pvc]: http://guides.rubygems.org/patterns/#pessimistic-version-constraint

## Copyright
Copyright (c) 2006-2016 Erik Michaels-Ober, John Nunemaker, Wynn Netherland, Steve Richert, Steve Agalloco.
See [LICENSE][] for details.

[license]: LICENSE.md
