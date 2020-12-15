## Next Release

## 6.1.0 (12/28/2019)

* Add skip_html_injection flag
* Remove writer hack in active_record6
* Use modern includes syntax in warnings
* Fix warning: The last argument is used as the keyword parameter

## 6.0.2 (08/20/2019)

* Fully support Rails 6.0

## 6.0.1 (06/26/2019)

* Add Bullet::ActiveJob
* Prevent "Maximum call stack exceeded" errors when used with Turbolinks

## 6.0.0 (04/25/2019)

* Add XHR support to Bullet
* Support Rails 6.0
* Handle case where ID is manually set on unpersisted record

## 5.9.0 (11/11/2018)

* Require Ruby 2.3+
* Support Mongo 7.x

## 5.8.0 (10/29/2018)

* Fix through reflection for rails 5.x
* Fix false positive in after_save/after_create callbacks
* Don't triger a preload error on "manual" preloads
* Avoid Bullet from making extra queries in mongoid6
* Support option for #first and #last on mongoid6.x
* Fix duplicate logs in mongoid 4.x and 5.x version
* Use caller for ruby 1.9 while caller_locations for 2.0+
* Extend stacktrace matching for sub-file precision
* Exclude configured bundler path in addition to '/vendor'
* Fix `caller_path` in `excluded_stacktrace_path`
* Update `uniform_notifier` dependency to add Sentry support
* Integrate awesomecode.io and refactor code

## 5.7.0 (12/03/2017)

* Support rails 5.2
* Implement Bullet.delete_whitelist to delete a specific whitelist definition
* Fix caller_path in the case of nil

## 5.6.0 (07/16/2017)

* Migrate alias_method to Module#prepend
* Add install generator
* Stack trace filter
* Fix rails 5.1 compatibility
* Fix inverse_of for rails 5
* Fix detect file attachment for rack #319

## 5.5.0 (12/30/2016)

* Display http request method #311
* Add close button to footer
* Raise an error if bullet does not support AR or Mongoid
* Avoid double backtrace
* Fix false alert on counter cache when associations are already loaded #288
* Fix "false alert" in rails 5 #239
* Do not support ActiveRecord 3.x and Mongoid 3.x / 4.x anymore

## 5.4.0 (10/09/2016)

* Support rails 5.1
* Extract stack trace filtering into module

## 5.3.0 (15/08/2016)

* Fix false alert on through association with join sql #301
* Fix association.target in `through_association` can be singular #302
* Support `find_by_sql` #303
* Fix env `REQUEST_URI`

## 5.2.0 (07/26/2016)

* Fix `has_cached_counter?` is not defined in HABTM #297
* Fix false alert if preloaded association has no records #260
* Support Rails 5.0.0

## 5.1.0 (05/21/2016)

* Fix false alert when `empty?` used with `counter_cache`
* Fix `alias_method_chain` deprecation for rails 5
* Add response handling for non-Rails Rack responses
* Fix false alert when querying immediately after creation
* Fix UnusedEagerLoading bug when multiple eager loading query include same objects

## 5.0.0 (01/06/2016)

* Support Rails 5.0.0.beta1
* Fix `has_many :through` infinite loop issue
* Support mongoid 5.0.0
* Do not report association queries immediately after object creation to
  require a preload
* Detect `counter_cache` for `has_many :through` association
* Compatible with `composite_primary_keys` gem
* Fix AR 4.2 SingularAssociation#reader result can be nil
* `perform_out_of_channel_notifications` should always be triggered
* Fix false positive with `belongs_to` -> `belongs_to` for active\_record 4.2
* Activate active\_record hacks only when Bullet already start
* Don't execute query when running `to_sql`
* Send backtrace to `uniform_notifier`
* Fix sse response check
* Dynamically delegate available notifiers to UniformNotifier
* Hotfix nil object when `add_impossible_object`
* Fix `has_one` then `has_many` associations in rails 4.2
* Append js and dom to html body in proper position

## 4.14.0 (10/03/2014)

* Support rails 4.2
* Polish notification output
* Fix warning: `*' interpreted as argument prefix

## 4.13.0 (07/19/2014)

* Support include? call on ar associations

## 4.12.0 (07/13/2014)

* Fix false n+1 queries caused by inversed objects.
* Replace .id with .primary_key_value
* Rename bullet_ar_key to bullet_key
* Fix rails sse detect
* Fix bullet using in test environment
* Memoize whoami

## 4.11.0 (06/24/2014)

* Support empty? call on ar associations
* Skip detecting if object is a new record

## 4.10.0 (06/06/2014)

* Handle join query smarter
* Support mongoid 4.0
* Thread safe
* Add debug mode

## 4.9.0 (04/30/2014)

* Add Bullet.stacktrace_includes option
* Applied keyword argument fixes on Ruby 2.2.0
* Add bugsnag notifier
* Support rails 4.1.0

## 4.8.0 (02/16/2014)

* Support rails 4.1.0.beta1
* Update specs to be RSpec 3.0 compatible
* Update latest minor version activerecord and mongoid on travis

## 4.7.0 (11/03/2013)

* Add coverall support
* Add helper to profile code outside a request
* Add activesupport dependency
* Add Bullet.raise notification
* Add Bullet.add_footer notification
* Fix activerecord4 warnings in test code

## 4.6.0 (04/18/2013)

* Fix Bullet::Rack to support sinatra

## 4.5.0 (03/24/2013)

* Add api way to access captured associatioin
* Allow disable n_plus_one_query, unused_eager_loading and counter_cache respectively
* Add whitelist

## 4.4.0 (03/15/2013)

* Remove disable_browser_cache option
* Compatible with Rails 4.0.0.beta1

## 4.3.0 (12/28/2012)

* Fix content-length for non ascii html
* Add mongoid 2.5.x support

## 4.2.0 (09/29/2012)

* Add Bullet::Dependency to check AR and mongoid version
* Add Rails 4 support
* Add airbrake notifier support

## 4.1.0 (05/30/2012)

* Add mongoid 3 support

## 4.0.0 (05/09/2012)

* Add mongoid support
