## master

## v2.2.8

* Leave emoji symbols intact when encoding URI fragment [#312](https://github.com/railsware/js-routes/issues/312)
* Use webpacker config variable instead of hardcode [#309](https://github.com/railsware/js-routes/issues/309)
* Use `File.exist?` to be compatible with all versions of ruby [#310](https://github.com/railsware/js-routes/issues/310)

## v2.2.7

* Fix ESM Tree Shaking [#306](https://github.com/railsware/js-routes/issues/306)

## v2.2.6

* Prefer to extend `javascript:build` instead of `assets:precompile`. [#305](https://github.com/railsware/js-routes/issues/305)
* Add stimulus framework application.js location to generators

## v2.2.5

* Upgraded eslint and prettier versions [#304](https://github.com/railsware/js-routes/issues/304)
* Fix middleware generator [#300](https://github.com/railsware/js-routes/issues/300)
* Support `params` special parameter

## v2.2.4

* Fix rails engine loading if sprockets is not in Gemfile. Fixes [#294](https://github.com/railsware/js-routes/issues/294)

## v2.2.3

* Fixed NIL module type namespace defintion [#297](https://github.com/railsware/js-routes/issues/297).
  * The patch may cause a problem with nested `namespace` option 
  * Ex. Value like `MyProject.Routes` requires to define `window.MyProject` before importing the routes file

## v2.2.2.

* Fix custom file path [#295](https://github.com/railsware/js-routes/issues/295)

## v2.2.1

* Improve generator to update route files on `assets:precompile` and add them to `.gitignore by default` [#288](https://github.com/railsware/js-routes/issues/288#issuecomment-1012182815)

## v2.2.0

* Use Rack Middleware to automatically update routes file in development [#288](https://github.com/railsware/js-routes/issues/288)
  * This setup is now a default recommended due to lack of any downside comparing to [ERB Loader](./Readme.md#webpacker) and [Manual Setup](./Readme.md#advanced-setup)

## v2.1.3

* Fix `default_url_options` bug. [#290](https://github.com/railsware/js-routes/issues/290)

## v2.1.2

* Improve browser window object detection. [#287](https://github.com/railsware/js-routes/issues/287)

## v2.1.1

* Added webpacker generator `./bin/rails generate js_routes:webpacker`
* Reorganized Readme to describe different setups with their pros and cons more clearly

## v2.1.0

* Support typescript defintions file aka `routes.d.ts`. See [Readme.md](./Readme.md#definitions) for more information.

## v2.0.8

* Forbid usage of `namespace` option if `module_type` is not `nil`. [#281](https://github.com/railsware/js-routes/issues/281).

## v2.0.7

* Remove source map annotation from JS file. Fixes [#277](https://github.com/railsware/js-routes/issues/277)
  * Generated file is not minified, so it is better to use app side bundler/compressor for source maps


## v2.0.6

* Disable `namespace` option default for all envs [#278](https://github.com/railsware/js-routes/issues/278)

## v2.0.5

* Fixed backward compatibility issue [#276](https://github.com/railsware/js-routes/issues/276)

## v2.0.4

* Fixed backward compatibility issue [#275](https://github.com/railsware/js-routes/issues/275)

## v2.0.3

* Fixed backward compatibility issue [#275](https://github.com/railsware/js-routes/issues/275)

## v2.0.2

* Fixed backward compatibility issue [#274](https://github.com/railsware/js-routes/issues/274)

## v2.0.1

* Fixed backward compatibility issue [#272](https://github.com/railsware/js-routes/issues/272)

## v2.0.0

Version 2.0 has some breaking changes.
See [UPGRADE TO 2.0](./VERSION_2_UPGRADE.md) for guidance.

* `module_type` option support
* `documentation` option spport
* Migrated implementation to typescript
* ESM tree shaking support
* Support camel case `toParam` version of `to_param` property

## v1.4.14

* Fix compatibility with UMD modules #237 [Comment](https://github.com/railsware/js-routes/issues/237#issuecomment-752754679)

## v1.4.13

* Improve compatibility with node environment #269.
* Change default file location configuration to Webpacker if both Webpacker and Sprockets are loaded

## v1.4.11

* Use app/javascript/routes.js as a default file location if app/javascript directory exists
* Add `default` export for better experience when used as es6 module

## v1.4.10

* Require engine only when sprockets is loaded #257.

## v1.4.9

* Allow to specify null namespace and receive routes as an object without assigning it anywhere #247

## v1.4.7

* Fix a LocalJumpError on secondary initialization of the app #248

## v1.4.6

* Fix regression of #244 in #243

## v1.4.5

* Fix escaping inside route parameters and globbing #244

## v1.4.4

* More informative stack trace for ParameterMissing error #235

## v1.4.3

* Proper implementation of the :subdomain option in routes generation

## v1.4.2

* Added JsRoutes namespace to Engine #230

## v1.4.1

* Fixed bug when js-routes is used in envs without window.location #224


## v1.4.0

* __breaking change!__ Implemented Routes.config() and Routes.configure instead of Routes.defaults

New methods support 4 options at the moment:

``` js
Routes.configuration(); // =>
/*
{
  prefix: "",
  default_url_options: {},
  special_options_key: '_options',
  serializer: function(...) { ... }
}
*/

Routes.configure({
 prefix: '/app',
 default_url_options: {format: 'json'},
 special_options_key: '_my_options_key',
 serializer: function(...) { ... }
});
```

## v1.3.3

* Improved optional parameters support #216

## v1.3.2

* Added `application` option #214

## v1.3.1

* Raise error object with id null passed as route paramter #209
* Sprockets bugfixes #212

## v1.3.0

* Introduce the special _options key. Fixes #86

## v1.2.9

* Fixed deprecation varning on Sprockets 3.7

## v1.2.8

* Bugfix warning on Sprockets 4.0 #202

## v1.2.7

* Drop support 1.9.3
* Add helper for indexOf, if no native implementation in JS engine
* Add sprockets3 compatibility
* Bugfix domain defaults to path #197

## v1.2.6

* Use default prefix from `Rails.application.config.relative_url_root` #186
* Bugfix route globbing with optional fragments bug #191

## v1.2.5

* Bugfix subdomain default parameter in routes #184
* Bugfix infinite recursion in some specific route sets #183

## v1.2.4

* Additional bugfixes to support all versions of Sprockets: 2.x and 3.x

## v1.2.3

* Sprockets ~= 3.0 support

## v1.2.2

* Sprockets ~= 3.0 support
* Support default parameters specified in route.rb file

## v1.2.1

* Fixes for Rails 5

## v1.2.0

* Support host, port and protocol inline parameters
* Support host, port and protocol parameters given to a route explicitly
* Remove all incompatibilities between actiondispatch and js-routes in handling route URLs

## v1.1.2

* Bugfix support nested object null parameters #164
* Bugfix support for nested optional parameters #162 #163

## v1.1.1

* Bugfix regression in serialisation on blank strings caused by [#155](https://github.com/railsware/js-routes/pull/155/files)

## v1.1.0

* Ensure routes are loaded, prior to generating them [#148](https://github.com/railsware/js-routes/pull/148)
* Use `flat_map` rather than `map{...}.flatten` [#149](https://github.com/railsware/js-routes/pull/149)
* URL escape routes.rb url to fix bad URI(is not URI?) error [#150](https://github.com/railsware/js-routes/pull/150)
* Fix for rails 5 - test rails-edge on travis allowing failure [#151](https://github.com/railsware/js-routes/pull/151)
* Adds `serializer` option [#155](https://github.com/railsware/js-routes/pull/155/files)

## v1.0.1

* Support sprockets-3
* Performance optimization of include/exclude options

## v1.0.0

 * Add the compact mode [#125](https://github.com/railsware/js-routes/pull/125)
 * Add support for host, protocol, and port configuration [#137](https://github.com/railsware/js-routes/pull/137)
 * Routes path specs [#135](https://github.com/railsware/js-routes/pull/135)
 * Support Rails 4.2 and Ruby 2.2 [#140](https://github.com/railsware/js-routes/pull/140)

## v0.9.9

* Bugfix Rails Engine subapplication route generation when they are nested [#120](https://github.com/railsware/js-routes/pull/120)

## v0.9.8

* Support AMD/Require.js [#111](https://github.com/railsware/js-routes/pull/111)
* Support trailing slash [#106](https://github.com/railsware/js-routes/pull/106)

## v0.9.7

* Depend on railties [#97](https://github.com/railsware/js-routes/pull/97)
* Fix typeof error for IE [#95](https://github.com/railsware/js-routes/pull/95)
* Fix testing on ruby-head [#92](https://github.com/railsware/js-routes/pull/92)
* Correct thread safety issue in js-routes generation [#90](https://github.com/railsware/js-routes/pull/90)
* Use the `of` operator to detect for `to_param` and `id` in objects [#87](https://github.com/railsware/js-routes/pull/87)
