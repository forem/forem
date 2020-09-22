⚠️ **_WARNING_**: You are viewing the README of the master branch which contains unreleased changes for version 2.0.0.
Please help us reach the [2.0.0 release milestone](https://github.com/oauth-xx/oauth2/milestone/1) by submitting PRs, or reviewing PRs and issues.

---

# OAuth2

If you need the readme for a released version of the gem please find it below:

| Version  | Release Date | Readme                                                   |
|----------|--------------|----------------------------------------------------------|
| 1.4.4    | Feb 12, 2020 | https://github.com/oauth-xx/oauth2/blob/v1.4.4/README.md |
| 1.4.3    | Jan 29, 2020 | https://github.com/oauth-xx/oauth2/blob/v1.4.3/README.md |
| 1.4.2    | Oct 1, 2019  | https://github.com/oauth-xx/oauth2/blob/v1.4.2/README.md |
| 1.4.1    | Oct 13, 2018 | https://github.com/oauth-xx/oauth2/blob/v1.4.1/README.md |
| 1.4.0    | Jun 9, 2017  | https://github.com/oauth-xx/oauth2/blob/v1.4.0/README.md |
| 1.3.1    | Mar 3, 2017  | https://github.com/oauth-xx/oauth2/blob/v1.3.1/README.md |
| 1.3.0    | Dec 27, 2016 | https://github.com/oauth-xx/oauth2/blob/v1.3.0/README.md |
| 1.2.0    | Jun 30, 2016 | https://github.com/oauth-xx/oauth2/blob/v1.2.0/README.md |
| 1.1.0    | Jan 30, 2016 | https://github.com/oauth-xx/oauth2/blob/v1.1.0/README.md |
| 1.0.0    | May 23, 2014 | https://github.com/oauth-xx/oauth2/blob/v1.0.0/README.md |
| < 1.0.0  | Find here    | https://github.com/oauth-xx/oauth2/tags                  |

[![Gem Version](http://img.shields.io/gem/v/oauth2.svg)][gem]
[![Total Downloads](https://img.shields.io/gem/dt/oauth2.svg)][gem]
[![Downloads Today](https://img.shields.io/gem/rt/oauth2.svg)][gem]
[![Build Status](http://img.shields.io/travis/oauth-xx/oauth2.svg)][travis]
[![Test Coverage](https://api.codeclimate.com/v1/badges/688c612528ff90a46955/test_coverage)][codeclimate-coverage]
[![Maintainability](https://api.codeclimate.com/v1/badges/688c612528ff90a46955/maintainability)][codeclimate-maintainability]
[![Depfu](https://badges.depfu.com/badges/6d34dc1ba682bbdf9ae2a97848241743/count.svg)][depfu]
[![Open Source Helpers](https://www.codetriage.com/oauth-xx/oauth2/badges/users.svg)][code-triage]
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)][source-license]
[![Documentation](http://inch-ci.org/github/oauth-xx/oauth2.png)][inch-ci]
[![FOSSA Status](https://app.fossa.io/api/projects/git%2Bgithub.com%2Foauth-xx%2Foauth2.svg?type=shield)][fossa1]

[gem]: https://rubygems.org/gems/oauth2
[travis]: http://travis-ci.org/oauth-xx/oauth2
[coveralls]: https://coveralls.io/r/oauth-xx/oauth2
[codeclimate-maintainability]: https://codeclimate.com/github/oauth-xx/oauth2/maintainability
[codeclimate-coverage]: https://codeclimate.com/github/oauth-xx/oauth2/test_coverage
[depfu]: https://depfu.com/github/oauth-xx/oauth2
[source-license]: https://opensource.org/licenses/MIT
[inch-ci]: http://inch-ci.org/github/oauth-xx/oauth2
[code-triage]: https://www.codetriage.com/oauth-xx/oauth2
[fossa1]: https://app.fossa.io/projects/git%2Bgithub.com%2Foauth-xx%2Foauth2?ref=badge_shield

### Oauth2 gem is looking for additional maintainers. See [#307](https://github.com/oauth-xx/oauth2/issues/307).

A Ruby wrapper for the OAuth 2.0 specification.

## Installation

    gem install oauth2

Or inside Gemfile

    gem 'oauth2'

## Resources
* [View Source on GitHub][code]
* [Report Issues on GitHub][issues]
* [Read More at the Wiki][wiki]

[code]: https://github.com/oauth-xx/oauth2
[issues]: https://github.com/oauth-xx/oauth2/issues
[wiki]: https://github.com/oauth-xx/oauth2/wiki

## Usage Examples

```ruby
require 'oauth2'
client = OAuth2::Client.new('client_id', 'client_secret', :site => 'https://example.org')

client.auth_code.authorize_url(:redirect_uri => 'http://localhost:8080/oauth2/callback')
# => "https://example.org/oauth/authorization?response_type=code&client_id=client_id&redirect_uri=http://localhost:8080/oauth2/callback"

token = client.auth_code.get_token('authorization_code_value', :redirect_uri => 'http://localhost:8080/oauth2/callback', :headers => {'Authorization' => 'Basic some_password'})
response = token.get('/api/resource', :params => { 'query_foo' => 'bar' })
response.class.name
# => OAuth2::Response
```

### DEBUGGING

Set an environment variable, however you would [normally do that](https://github.com/bkeepers/dotenv).

```ruby
# will log both request and response, including bodies
ENV['OAUTH_DEBUG'] = 'true'
```

By default, debug output will go to `$stdout`. This can be overridden when
initializing your OAuth2::Client.

```ruby
require 'oauth2'
client = OAuth2::Client.new(
  'client_id',
  'client_secret',
  :site   => 'https://example.org',
  :logger => Logger.new('example.log', 'weekly')
)
```

## OAuth2::Response

The `AccessToken` methods `#get`, `#post`, `#put` and `#delete` and the generic `#request`
will return an instance of the #OAuth2::Response class.

This instance contains a `#parsed` method that will parse the response body and
return a Hash if the `Content-Type` is `application/x-www-form-urlencoded` or if
the body is a JSON object.  It will return an Array if the body is a JSON
array.  Otherwise, it will return the original body string.

The original response body, headers, and status can be accessed via their
respective methods.

## OAuth2::AccessToken

If you have an existing Access Token for a user, you can initialize an instance
using various class methods including the standard new, `from_hash` (if you have
a hash of the values), or `from_kvform` (if you have an
`application/x-www-form-urlencoded` encoded string of the values).

## OAuth2::Error

On 400+ status code responses, an `OAuth2::Error` will be raised.  If it is a
standard OAuth2 error response, the body will be parsed and `#code` and `#description` will contain the values provided from the error and
`error_description` parameters.  The `#response` property of `OAuth2::Error` will
always contain the `OAuth2::Response` instance.

If you do not want an error to be raised, you may use `:raise_errors => false`
option on initialization of the client.  In this case the `OAuth2::Response`
instance will be returned as usual and on 400+ status code responses, the
Response instance will contain the `OAuth2::Error` instance.

## Authorization Grants

Currently the Authorization Code, Implicit, Resource Owner Password Credentials, Client Credentials, and Assertion
authentication grant types have helper strategy classes that simplify client
use. They are available via the `#auth_code`, `#implicit`, `#password`, `#client_credentials`, and `#assertion` methods respectively.

```ruby
auth_url = client.auth_code.authorize_url(:redirect_uri => 'http://localhost:8080/oauth/callback')
token = client.auth_code.get_token('code_value', :redirect_uri => 'http://localhost:8080/oauth/callback')

auth_url = client.implicit.authorize_url(:redirect_uri => 'http://localhost:8080/oauth/callback')
# get the token params in the callback and
token = OAuth2::AccessToken.from_kvform(client, query_string)

token = client.password.get_token('username', 'password')

token = client.client_credentials.get_token

token = client.assertion.get_token(assertion_params)
```

If you want to specify additional headers to be sent out with the
request, add a 'headers' hash under 'params':

```ruby
token = client.auth_code.get_token('code_value', :redirect_uri => 'http://localhost:8080/oauth/callback', :headers => {'Some' => 'Header'})
```

You can always use the `#request` method on the `OAuth2::Client` instance to make
requests for tokens for any Authentication grant type.


## Supported Ruby Versions

This library aims to support and is [tested against][travis] the following Ruby
implementations:

### Rubies with support ending at Oauth2 1.x

For information on supported Rubies for the current 1.x release of oauth2 see the [README for 1.4.x](https://github.com/oauth-xx/oauth2/blob/1-4-stable/README.md)

---

### Rubies with continued support past Oauth2 2.x

* Ruby 2.2 - Support ends with version 2.x series
* Ruby 2.3 - Support ends with version 3.x series
  - [JRuby 9.1][jruby-9.1] (targets MRI v2.3) 
* Ruby 2.4 - Support ends with version 4.x series
* Ruby 2.5 - Support ends with version 5.x series
  - [JRuby 9.2][jruby-9.2] (targets MRI v2.5)
  - [truffleruby][truffleruby] (targets MRI 2.5)
* Ruby 2.6 - Support ends with version 6.x series
* Ruby 2.7 - Support ends with version 7.x series

[jruby-1.7]: https://www.jruby.org/2017/05/11/jruby-1-7-27.html
[jruby-9.0]: https://www.jruby.org/2016/01/26/jruby-9-0-5-0.html
[jruby-9.1]: https://www.jruby.org/2017/05/16/jruby-9-1-9-0.html
[jruby-9.2]: https://www.jruby.org/2018/05/24/jruby-9-2-0-0.html
[truffleruby]: https://github.com/oracle/truffleruby

If something doesn't work on one of these interpreters, it's a bug.

This library may inadvertently work (or seem to work) on other Ruby
implementations, however support will only be provided for the versions listed
above.

If you would like this library to support another Ruby version, you may
volunteer to be a maintainer. Being a maintainer entails making sure all tests
run and pass on that implementation. When something breaks on your
implementation, you will be responsible for providing patches in a timely
fashion. If critical issues for a particular implementation exist at the time
of a major release, support for that Ruby version may be dropped.

## Versioning

This library aims to adhere to [Semantic Versioning 2.0.0][semver].
Violations of this scheme should be reported as bugs. Specifically,
if a minor or patch version is released that breaks backward
compatibility, a new version should be immediately released that
restores compatibility. Breaking changes to the public API will
only be introduced with new major versions.

As a result of this policy, you can (and should) specify a
dependency on this gem using the [Pessimistic Version Constraint][pvc] with two digits of precision.

For example:

```ruby
spec.add_dependency 'oauth2', '~> 1.4'
```

[semver]: http://semver.org/
[pvc]: http://guides.rubygems.org/patterns/#pessimistic-version-constraint

## License

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)][source-license]

- Copyright (c) 2011-2013 Michael Bleigh and Intridea, Inc.
- Copyright (c) 2017-2018 [oauth-xx organization][oauth-xx]
- See [LICENSE][license] for details.

[![FOSSA Status](https://app.fossa.io/api/projects/git%2Bgithub.com%2Foauth-xx%2Foauth2.svg?type=large)][fossa2]

[license]: LICENSE
[oauth-xx]: https://github.com/oauth-xx
[fossa2]: https://app.fossa.io/projects/git%2Bgithub.com%2Foauth-xx%2Foauth2?ref=badge_large

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/oauth-xx/oauth2. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## Code of Conduct

Everyone interacting in the OAuth2 project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/oauth-xx/oauth2/blob/master/CODE_OF_CONDUCT.md).
