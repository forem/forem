## 2.4.0 (2024-11-11)

- Added `html5` option
- Improved generator for Active Record encryption and MySQL
- Removed support for Ruby < 3.1 and Rails < 7
- Removed support for Mongoid < 8

## 2.3.1 (2024-09-09)

- Fixed deprecation warning with Rails 7.1

## 2.3.0 (2024-06-01)

- Added support for secret token rotation
- Improved secret token generation

## 2.2.0 (2023-07-02)

- Removed support for Ruby < 3 and Rails < 6.1

## 2.1.3 (2022-06-12)

- Updated messages generator for Lockbox 1.0
- Fixed deprecation warning with Redis 4.6+

## 2.1.2 (2022-02-09)

- Fixed external redirects with Rails 7

## 2.1.1 (2021-12-13)

- Added experimental support for Active Record encryption

## 2.1.0 (2021-09-25)

- Fixed mailer `default_url_options` not being applied to click links

## 2.0.3 (2021-03-31)

- Fixed `utm_params` and `track_clicks` stripping `<head>` tags from messages

## 2.0.2 (2021-03-14)

- Added support for Mongoid to database subscriber

## 2.0.1 (2021-03-08)

- Added database subscriber

## 2.0.0 (2021-03-06)

- Made `to` field encrypted by default for new installations
- Added click analytics for Redis
- Added send events to subscribers
- Removed support for Rails < 5.2

Breaking changes

- The `track` method has been broken into `has_history` for message history, `utm_params` for UTM tagging, and `track_clicks` for click analytics
- Message history is no longer enabled by default
- Open tracking has been removed
- `:message` is no longer included in click events
- Users are shown a link expired page when signature verification fails instead of being redirected to the homepage when `AhoyEmail.invalid_redirect_url` is not set

## 1.1.1 (2021-03-06)

- Added support for classes for subscribers
- Use `datetime` type in migration

## 1.1.0 (2019-07-15)

- Made `opened_at` optional with click tracking
- Fixed secret token for environment variables
- Removed support for Rails 4.2

## 1.0.3 (2019-02-18)

- Fixed custom message model
- Fixed `message` option with proc

## 1.0.2 (2018-10-02)

- Fixed error with Ruby < 2.5
- Fixed UTM parameters storage on model

## 1.0.1 (2018-09-27)

- Use observer instead of interceptor

## 1.0.0 (2018-09-27)

- Removed support for Rails < 4.2

Breaking changes

- UTM tagging, open tracking, and click tracking are no longer enabled by default
- Only sent emails are recorded
- Proc options are now executed in the context of the mailer and take no arguments
- Invalid options now throw an `ArgumentError`
- `AhoyEmail.track` was removed in favor of `AhoyEmail.default_options`
- The `heuristic_parse` option was removed and is now the default

## 0.5.2 (2018-04-26)

- Fixed secret token for Rails 5.2
- Added `heuristic_parse` option

## 0.5.1 (2018-04-19)

- Fixed deprecation warning in Rails 5.2
- Added `unsubscribe_links` option
- Allow `message_model` to accept a proc
- Use `references` in migration

## 0.5.0 (2017-05-01)

- Added support for Rails 5.1
- Added `invalid_redirect_url`

## 0.4.0 (2016-09-01)

- Fixed `belongs_to` error in Rails 5
- Include `safely_block` gem without polluting global namespace

## 0.3.2 (2016-07-27)

- Fixed deprecation warning for Rails 5
- Do not track content by default on fresh installations

## 0.3.1 (2016-05-11)

- Fixed deprecation warnings
- Fixed `stack level too deep` error

## 0.3.0 (2015-12-16)

- Added safely for error reporting
- Fixed error with `to`
- Prevent duplicate records when mail called multiple times

## 0.2.4 (2015-07-29)

- Added `extra` option for extra attributes

## 0.2.3 (2015-03-22)

- Save utm parameters
- Added `url_options`
- Skip tracking for `mailto` links
- Only set secret token if not already set

## 0.2.2 (2014-08-31)

- Fixed secret token for Rails 4.1
- Fixed links with href
- Fixed message id for Rails 3.1

## 0.2.1 (2014-05-26)

- Added `only` and `except` options

## 0.2.0 (2014-05-10)

- Enable tracking when track is called by default

## 0.1.5 (2014-05-09)

- Rails 3 fix

## 0.1.4 (2014-05-04)

- Try not to rewrite unsubscribe links

## 0.1.3 (2014-05-03)

- Added `to` and `mailer` fields
- Added subscribers for open and click events

## 0.1.2 (2014-05-01)

- Added `AhoyEmail.track` (fix)

## 0.1.1 (2014-04-30)

- Use secure compare for signature verification
- Fixed deprecation warnings

## 0.1.0 (2014-04-29)

- Changed option names

## 0.0.2 (2014-04-29)

- Added open and click tracking
- Added UTM parameters
- Rescue errors

## 0.0.1 (2014-04-28)

- First release
