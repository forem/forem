# EmailValidator

[![Build Status](https://travis-ci.com/K-and-R/email_validator.svg?branch=master)](http://travis-ci.com/K-and-R/email_validator)
[![Code Climate](https://codeclimate.com/github/K-and-R/email_validator/badges/gpa.svg)](https://codeclimate.com/github/K-and-R/email_validator)
[![Test Coverage](https://codeclimate.com/github/K-and-R/email_validator/badges/coverage.svg)](https://codeclimate.com/github/K-and-R/email_validator/coverage)

An email validator for Rails 3+.

Supports RFC-2822-compliant and RFC-5321-compliant email validation using RFC-3696 validation.

Formerly found at: <https://github.com/balexand/email_validator>

## Validation philosophy

The default validation provided by this gem (the `:loose` configuration option)
is extremely loose. It just checks that there's an `@` with something before and
after it without any whitespace. See [this article by David Gilbertson](https://medium.com/hackernoon/the-100-correct-way-to-validate-email-addresses-7c4818f24643)
for an explanation of why.

We understand that many use cases require an increased level of validation. This
is supported by using the `:strict` validation mode. Additionally, the `:rfc`
RFC-compliant mode will consider technically valid emails address as valid which
may not be wanted, such as the valid `user` or `user@somehost` addresses. These
would be valid in `:rfc` mode but not valid in `:loose` or `:strict`.

## Installation

Add to your Gemfile:

```ruby
gem 'email_validator'
```

Run:

```bash
bundle install
```

## Usage

Add the following to your model:

```ruby
validates :my_email_attribute, email: true
```

You may wish to allow domains without a FQDN, like `user@somehost`. While this
is technically a valid address, it is uncommon to consider such address valid.
We will consider them valid by default with the `:loose` checking. Disallowed
by setting `require_fqdn: true` or by enabling `:strict` checking:

```ruby
validates :my_email_attribute, email: {mode: :strict, require_fqdn: true}
```

You can also limit to a single domain (e.g: you have separate `User` and
`AdminUser` models and want to ensure that `AdminUser` emails are on a specific
domain):

```ruby
validates :my_email_attribute, email: {domain: 'example.com'}
```

## Configuration

Default configuration can be overridden by setting options in `config/initializers/email_validator.rb`:

```ruby
if defined?(EmailValidator)
  # To completely override the defaults
  EmailValidator.default_options = {
    allow_nil: false,
    domain: nil,
    require_fqdn: nil,
    mode: :loose
  }

  # or just a few options
  EmailValidator.default_options.merge!({ domain: 'mydomain.com' })
end
```

### Loose mode

This it the default validation mode of this gem. It is intentionally extremely
loose (see the [Validation Philosophy section](#validation_philosophy) above. It
just checks that there's an `@` with something before and after it without any
whitespace.

### Strict mode

Enabling `:strict` checking will check for a "normal" email format that would
be expected in most common everyday usage. Strict mode basically checks for a
properly sized and formatted mailbox label, a single "@" symbol, and a properly
sized and formatted FQDN. Enabling `:strict` mode will also enable `:require_fqdn`
configuration option.

Strict mode can be enabled globally by requiring `email_validator/strict` in
your `Gemfile`, by setting the option in `config/initializers/email_validator.rb`,
or by specifying the option in a specific `validates` call.

* `Gemfile`:

  ```ruby
  gem 'email_validator', require: 'email_validator/strict'
  ```

* `config/initializers/email_validator.rb`:

  ```ruby
  if defined?(EmailValidator)
    EmailValidator.default_options[:mode] = :strict
  end
  ```

* `validates` call:

  ```ruby
  validates :my_email_attribute, email: {mode: :strict}
  ```

### RFC mode

In order to have RFC-compliant validation (according to [http://www.remote.org/jochen/mail/info/chars.html](https://web.archive.org/web/20150508102948/http://www.remote.org/jochen/mail/info/chars.html)),
enable `:rfc` mode.

You can do this globally by requiring `email_validator/rfc` in your `Gemfile`,
by setting the options in `config/initializers/email_validator.rb`, or you can do
this in a specific `validates` call.

* `Gemfile`:

  ```ruby
  gem 'email_validator', require: 'email_validator/rfc'
  ```

* `config/initializers/email_validator.rb`:

  ```ruby
  if defined?(EmailValidator)
    EmailValidator.default_options[:mode] = :rfc
  end
  ```

* `validates` call:

  ```ruby
  validates :my_email_attribute, email: {mode: :rfc}
  ```

## Validation outside a model

If you need to validate an email outside a model, you can get the regexp:

### Loose/default mode

```ruby
EmailValidator.valid?('narf@example.com') # boolean
```

### Requiring a FQDN

```ruby
EmailValidator.valid?('narf@somehost') # boolean false
EmailValidator.invalid?('narf@somehost', require_fqdn: false) # boolean true
```

_NB: Enabling strict mode (`mode: :strict`) enables `require_fqdn`
(`require_fqdn: true`), overridding any `require_fqdn: false` while
`mode: :strict` is set._

### Requiring a specific domain

```ruby
EmailValidator.valid?('narf@example.com', domain: 'foo.com') # boolean false
EmailValidator.invalid?('narf@example.com', domain: 'foo.com') # boolean true
```

### Strict mode

```ruby
EmailValidator.regexp(mode: :strict) # returns the regex
EmailValidator.valid?('narf@example.com', mode: :strict) # boolean
```

### RFC mode

```ruby
EmailValidator.regexp(mode: :rfc) # returns the regex
EmailValidator.valid?('narf@example.com', mode: :rfc) # boolean
```

## Thread safety

This gem is thread safe, with one caveat: `EmailValidator.default_options` must
be configured before use in a multi-threaded environment. If you configure
`default_options` in a Rails initializer file, then you're good to go since
initializers are run before worker threads are spawned.

## Alternative gems

Do you prefer a different email validation gem? If so, open an issue with a brief
explanation of how it differs from this gem. I'll add a link to it in this README.

* [`email_address`](https://github.com/afair/email_address) (<https://github.com/K-and-R/email_validator/issues/58>)
* [`email_verifier`](https://github.com/kamilc/email_verifier) (<https://github.com/K-and-R/email_validator/issues/65>)

## Maintainers

All thanks is given to [Brian Alexander (balexand)](https://github.com/balexand)
for is initial work on this gem.

Currently maintained by:

* Karl Wilbur (<https://github.com/karlwilbur>)
* K&R Software (<https://github.com/K-and-R>)
