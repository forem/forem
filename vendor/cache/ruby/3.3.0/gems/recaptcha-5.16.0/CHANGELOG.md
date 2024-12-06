## Next

## 5.16.0
* Allow usage of `options[:turbo]` as well as `options[:turbolinks]` for `recaptcha_v3`

## 5.15.0
* Add 3.2 to the list of Ruby CI versions
* Add ability to submit verify_recaptcha via POST with JSON Body with `options[:json] = true`

## 5.14.0
* drop json dependency

## 5.13.1
* Permit actions as symbol

## 5.13.0
* Added option to ignore_no_element.

## 5.12.3
* Remove score fallback for enterprise
* Update enterprise tests to v1 assessment schema

## 5.12.2
* Fix minimum score for enterprise

## 5.12.1
* Fix Japanese locale

## 5.12.0
* Added Japanese locale

## 5.11.0
* Added Dutch locale

## 5.10.1
* Fix enterprise_verify_url #415

## 5.10.0
* Drop ruby 2.4 2.5 2.6
* Add maxiumm score support for hcaptcha

## 5.9.0
* Gracefully handle invalid params

## 5.8.1
* Allow configuring response limit

## 5.8.0
* Add support for the enterprise API

## 5.7.0
* french locale
* drop ruby 2.3

## 5.6.0
* Allow multiple invisible recaptchas on a single page by setting custom selector

## 5.5.0
* add `recaptcha_reply` controller method for better debugging/inspection

## 5.4.1
* fix v2 vs 'data' postfix

## 5.4.0
* added 'data' postfix to g-recaptcha-response attribute name to avoid collisions

## 5.3.0
* turbolinks support

## 5.2.0
* remove dependency on rails methods

## 5.1.0
* Added default translations for rails/i18n
* use recaptcha.net for the script tag

## 5.0.0
* Changed host to Recaptcha.net
* Add v3 API support
* Renamed `Recaptcha::ClientHelper` to `Recaptcha::Adapters::ViewMethods`
* Renamed `Recaptcha::Verify` to `Recaptcha::Adapters::ControllerMethods`

## 4.12.0 - 2018-08-30
* add `input` option to `invisible_recaptcha_tags`'s `ui` setting

## 4.11.1 - 2018-08-08
* leave `tabindex` attribute alone for `invisible_recaptcha_tags`

## 4.11.0 - 2018-08-06
* prefer RAILS_ENV over RACK_ENV #286

## 4.0.0 - 2016-11-14
* public_key -> site_key and private_key -> secret_key

## 3.4.0 - 2016-11-01
* Update fallback html

## 3.2.0 - 2016-06-13
* remove SKIP_VERIFY_ENV constant, use `skip_verify_env` instance variable instead

## 3.1.0 - 2016-06-10
* better error messages
* frozen constants

## 3.0.0 - 2016-05-27
* remove all non-ssl options

## 2.3.0 - 2016-05-25
* enable ssl verification by default ... disable via `disable_ssl_verification = true`

## 2.2.0 - 2016-05-23
* Add global hostname validator config
* Clean up after with_configuration exception

## 2.1.0 - 2016-05-19
* do not query google if repactcha was not submitted

## 2.0.0 - 2016-05-17
* remove stoken support, must use custom domain verification or domain whitelist

## 1.3.0 - 2016-04-07
* do not set model error and flash

## 1.2.0 - 2016-04-01
* custom domain validation

## 1.1.0 - 2016-01-27
* support RACK_ENV

## 1.0.2 - 2015-11-30
* nice deprecations for api_version

## 1.0.1 - 2015-11-30
* no longer defines `Rails` when `recaptcha/rails` is required

## 1.0.0 - 2015-11-30
* remove api v1 support
* remove ssl_api_server_url, nonssl_api_server_url, change api_server_url to always need ssl option
* removed activesupport dependency for .to_query
* made flash and models both have descriptive errors

## 0.6.0 - 2015-11-19
* extract token module
* need to use `gem "recaptcha", require: "recaptcha/rails"` to get rails helpers installed

## 0.5.0 - 2015-11-18
* size option
* support disabling stoken
* support Rails.env

## 0.4.0 / 2015-03-22

* Add support for ReCaptcha v2 API
* V2 API requires `g-recaptcha-response` parameters; https://github.com/ambethia/recaptcha/pull/114

## 0.3.6 / 2012-01-07

* Many documentation changes
* Fixed deprecations in dependencies
* Protocol relative JS includes
* Fixes for options hash
* Fixes for failing tests

## 0.3.5 / 2012-05-02

* I18n for error messages
* Rails: delete flash keys if unused

## 0.3.4 / 2011-12-13

* Rails 3
* Remove jeweler

## 0.2.2 / 2009-09-14

* Add a timeout to the validator
* Give the documentation some love

## 0.2.1 / 2009-09-14

* Removed Ambethia namespace, and restructured classes a bit
* Added an example rails app in the example-rails branch

## 0.2.0 / 2009-09-12

* RecaptchaOptions AJAX API Fix
* Added 'cucumber' as a test environment to skip
* Ruby 1.9 compat fixes
* Added option :message => 'Custom error message' to verify_recaptcha
* Removed dependency on ActiveRecord constant
* Add I18n

## 0.1.0 / 2008-2-8

* 1 major enhancement
* Initial Gem Release
