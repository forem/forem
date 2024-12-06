## 0.25.4

* Added read_only UI config option (https://github.com/jnunemaker/flipper/pull/679)

## 0.25.3

* Added configurable confirm warning for fully enabling a feature (https://github.com/jnunemaker/flipper/pull/665)
* Update rack protection to < 4 (https://github.com/jnunemaker/flipper/pull/675)
* Check sadd_returns_boolean on the actual client class rather than ::Redis (https://github.com/jnunemaker/flipper/pull/677)

## 0.25.2

* Fix deprecation warnings for Redis >= 4.8.0 (https://github.com/jnunemaker/flipper/pull/660)

## 0.25.1

### Additions/Changes

* ActiveRecord: use provided `gate_class` option when calling `#get_all` (https://github.com/jnunemaker/flipper/pull/647)
* Relaxed the rack-protection version to support latest (https://github.com/jnunemaker/flipper/commit/f4a41c541ccf14c535a61c6bc6fe7eeabbfc7e71).
* Configure ActiveRecord adapter immediately upon require of flipper-active_record (https://github.com/jnunemaker/flipper/pull/652)

## 0.25.0

### Additions/Changes

* Added a prompt in Flipper UI for the 'Delete' button to prevent accidental delete of features (https://github.com/jnunemaker/flipper/pull/625)
* Added failsafe adapter (https://github.com/jnunemaker/flipper/pull/626)
* Removed previously deprecated options and settings. Those upgrading from `<0.21` should upgrade to `~>0.24` first and fix any deprecation warnings when initializing Flipper. (https://github.com/jnunemaker/flipper/pull/627)
* ActiveRecord: base class for internal models (https://github.com/jnunemaker/flipper/pull/629)
* Remove use of `Rack::BodyProxy` in the memoizer middleware (https://github.com/jnunemaker/flipper/pull/631)

## 0.24.1

### Additions/Changes

* flipper-api: `exclude_gates` parameter to exclude gate data in GETs (https://github.com/jnunemaker/flipper/pull/572).
* Make it possible to disable internal memoization (https://github.com/jnunemaker/flipper/pull/612).
* Add Flipper::Actor#hash so actors can be hash keys (https://github.com/jnunemaker/flipper/pull/616).
* Pretty Up `rails routes` again and make rack-protection dependency less strict (https://github.com/jnunemaker/flipper/pull/619).
* Add kwargs for method_missing using ruby 3.0 (https://github.com/jnunemaker/flipper/pull/620).
* Relax the rack-protection dependency (https://github.com/jnunemaker/flipper/commit/c1cb9cd78140c2b09123687642558101e6e5d37d).

## 0.24.0

### Additions/Changes

* Add Ruby 3.0 and 3.1 to the CI matrix and fix groups block arity check for ruby 3 (https://github.com/jnunemaker/flipper/pull/601)
* Removed support for Ruby 2.5 (which was end of line 9 months ago)
* Add (alpha) client side instrumentation of events to cloud (https://github.com/jnunemaker/flipper/pull/602)
* Fix deprecated uses of Redis#pipelined (https://github.com/jnunemaker/flipper/pull/603). redis-rb >= 3 now required.
* Fix Flipper UI Rack application when `Rack::Session::Pool` is used to build it (https://github.com/jnunemaker/flipper/pull/606).

## 0.23.1

### Additions/Changes

* Relax dalli version constraint (https://github.com/jnunemaker/flipper/pull/596)

### Bug Fixes

* Fix railtie initialization to mount middleware after config/intializers/* (https://github.com/jnunemaker/flipper/pull/586)

## 0.23.0

### Additions/Changes

* Allow some HTML in banner and descriptions (https://github.com/jnunemaker/flipper/pull/570).
* Moved some cloud headers to http client (https://github.com/jnunemaker/flipper/pull/567).
* Update flipper-ui jquery and bootstrap versions (https://github.com/jnunemaker/flipper/issues/565 and https://github.com/jnunemaker/flipper/pull/566).
* Moved docs to www.flippercloud.io/docs (https://github.com/jnunemaker/flipper/pull/574).
* PStore adapter now defaults to thread safe and no longer supports `.thread_safe` (https://github.com/jnunemaker/flipper/commit/4048704fefe41b716015294a19a0b94546637630).
* Add failover adapter (https://github.com/jnunemaker/flipper/pull/584).
* Improve http adapter error message (https://github.com/jnunemaker/flipper/pull/587).
* Rails 7 support (mostly in https://github.com/jnunemaker/flipper/pull/592).

## 0.22.2

### Additions/Changes

* Allow adding multiple actors at once in flipper-ui via comma separation (configurable via `Flipper::UI.configuration.actors_separator`) (https://github.com/jnunemaker/flipper/pull/556)

### Bug Fixes

* Fix railtie initialization to avoid altering middleware order (https://github.com/jnunemaker/flipper/pull/563)

## 0.22.1

### Additions/Changes

* Remove Octicons and replace with a pure CSS status circle (https://github.com/jnunemaker/flipper/pull/547)
* Rescue unique errors in AR and Sequel when setting value (https://github.com/jnunemaker/flipper/commit/87f5a98bce7baad7a27b75b5bce3256967769f27)
* Add a Content-Security-Policy to flipper-ui (https://github.com/jnunemaker/flipper/pull/552)
* Fix Synchronizer issue that occurs for ActiveRecord adapter (https://github.com/jnunemaker/flipper/pull/554)

## 0.22.0

### Additions/Changes

* Enable log subscriber by default in Rails (https://github.com/jnunemaker/flipper/pull/525)
* Remove memoizer from API and UI (https://github.com/jnunemaker/flipper/pull/527). If you are using the UI or API without configuring the default instance of Flipper, you'll need to enable memoization if you want it. For examples, see the examples/ui and examples/api directories.
* Fix SQL reserved word use in get_all for ActiveRecord and Sequel (https://github.com/jnunemaker/flipper/pull/536).
* Handle spaces in names gracefully in UI (https://github.com/jnunemaker/flipper/pull/541).

## 0.21.0

### Additions/Changes

* Default to using memory adapter (https://github.com/jnunemaker/flipper/pull/501)
* Adapters now configured on require when possible (https://github.com/jnunemaker/flipper/pull/502)
* Added cloud recommendation to flipper-ui. Can be disabled with `Flipper::UI.configure { |config| config.cloud_recommendation = false }`. Just want to raise awareness that more is available if people want it (https://github.com/jnunemaker/flipper/pull/504)
* Added default `flipper_id` implementation via `Flipper::Identifier` and automatically included it in ActiveRecord and Sequel models (https://github.com/jnunemaker/flipper/pull/505)
* Deprecate superflous sync_method setting (https://github.com/jnunemaker/flipper/pull/511)
* Flipper is now pre-configured when used with Rails. By default, it will [memoize and preload all features for each request](https://flippercloud.io/docs/optimization#memoization). (https://github.com/jnunemaker/flipper/pull/506)

### Upgrading

You should be able to upgrade to 0.21 without any breaking changes. However, if you want to simplify your setup, you can remove some configuration that is now handled automatically:

1. Adapters are configured when on require, so unless you are using caching or other customizations, you can remove adapter configuration.

    ```diff
    # config/initializers/flipper.rb
    - Flipper.configure do |config|
    -   config.default { Flipper.new(Flipper::Adapters::ActiveRecord.new) }
    - end
    ```

2. `Flipper::Middleware::Memoizer` will be enabled by default -- including preloading. **Note**: You may want to disable preloading (see below) if you have > 100 features.

    ```diff
    # config/initializers/flipper.rb
    - Rails.configuration.middleware.use Flipper::Middleware::Memoizer,
    -   preload: [:stats, :search, :some_feature]
    + Rails.application.configure do
    +   # Uncomment to configure which features to preload on all requests
    +   # config.flipper.preload = [:stats, :search, :some_feature]
    +   #
    +   # Or, you may want to disable preloading entirely:
    +   # config.flipper.preload = false
    + end
    ```

3. `#flipper_id`, which is used to enable features for specific actors, is now defined by [Flipper::Identifier](lib/flipper/identifier.rb) on all ActiveRecord and Sequel models. You can remove your implementation if it is in the form of `ModelName;id`.

4. When using `flipper-cloud`, The `Flipper::Cloud.app` webhook receiver is now mounted at `/_flipper` by default.

    ```diff
    # config/routes.rb
    - mount Flipper::Cloud.app, at: "/_flipper"
    ```

## 0.20.4

### Additions/Changes

* Allow actors and time gates to deal with decimal percentages (https://github.com/jnunemaker/flipper/pull/492)
* Change Flipper::Cloud::Middleware to receive webhooks at / in addition to /webhooks.
* Add `write_through` option to ActiveSupportCacheStore adapter to support write-through caching (https://github.com/jnunemaker/flipper/pull/512)

## 0.20.3

### Additions/Changes

* Changed the internal structure of how the memory adapter stores things.

## 0.20.2

### Additions/Changes

* Http adapter now raises error when enable/disable/add/remove/clear fail.
* Cloud adapter sends some extra info like hostname, ruby version, etc. for debugging and decision making.

## 0.20.1

### Additions/Changes

* Just a minor tweak to cloud webhook middleware to provide more debugging information about why a hook wasn't successful.

## 0.20.0

### Additions/Changes

* Add support for webhooks to `Flipper::Cloud` (https://github.com/jnunemaker/flipper/pull/489).

## 0.19.1

### Additions/Changes

* Bump rack-protection version to < 2.2 (https://github.com/jnunemaker/flipper/pull/487)
* Add memoizer_options to Flipper::Api.app (https://github.com/jnunemaker/flipper/commit/174ad4bb94046a25c432d3c53fe1ff9f5a76d838)

## 0.19.0

### Additions/Changes

* 100% of actors is now considered conditional. Feature#on?, Feature#conditional?, Feature#state would all be affected. See https://github.com/jnunemaker/flipper/issues/463 for more.
* Several doc updates.

## 0.18.0

### Additions/Changes

* Add support for feature descriptions to flipper-ui (https://github.com/jnunemaker/flipper/pull/461).
* Remove rubocop (https://github.com/jnunemaker/flipper/pull/469).
* flipper-ui redesign (https://github.com/jnunemaker/flipper/pull/470).
* Removed support for ruby 2.4.
* Added support for ruby 2.7.
* Removed support for Rails 4.x.x.
* Removed support for customizing actors, groups, % of actors and % of time text in flipper-ui in favor of automatic and more descriptive text.

## 0.17.2

### Additions/Changes

* Avoid errors on import when there are no features and shared specs/tests for get all with no features (https://github.com/jnunemaker/flipper/pull/441 and https://github.com/jnunemaker/flipper/pull/442)
* ::ActiveRecord::RecordNotUnique > ActiveRecord::RecordNotUnique (https://github.com/jnunemaker/flipper/pull/444)
* Clear gate values on enable (https://github.com/jnunemaker/flipper/pull/454)
* Remove use of multi from redis adapter (https://github.com/jnunemaker/flipper/pull/451)

## 0.17.1

* Fix require in flipper-active_record (https://github.com/jnunemaker/flipper/pull/437)

## 0.17.0

### Additions/Changes

* Allow shorthand block notation on group types (https://github.com/jnunemaker/flipper/pull/406)
* Relax active record/support constraints to support Rails 6 (https://github.com/jnunemaker/flipper/pull/409)
* Allow disabling fun (https://github.com/jnunemaker/flipper/pull/413)
* Include thing_value in payload of Instrumented#enable and #disable (https://github.com/jnunemaker/flipper/pull/417)
* Replace Erubis with Erubi (https://github.com/jnunemaker/flipper/pull/407)
* Allow customizing Rack::Protection middleware list (https://github.com/jnunemaker/flipper/pull/385)
* Allow setting write_timeout for ruby 2.6+ (https://github.com/jnunemaker/flipper/pull/433)
* Drop support for Ruby 2.1, 2.2, and 2.3 (https://github.com/jnunemaker/flipper/commit/cf58982e70de5e6963b018ceced4f36a275f5b5d)
* Add support for Ruby 2.6 (https://github.com/jnunemaker/flipper/commit/57888311449ec81184d3d47ba9ae5cb1ad4a2f45)
* Remove support for Rails 3.2 (https://github.com/jnunemaker/flipper/commit/177c48c4edf51d4e411e7c673e30e06d1c66fb40)
* Add write_timeout for flipper http adapter for ruby 2.6+ (https://github.com/jnunemaker/flipper/pull/433)
* Relax moneta version to allow for < 1.2 (https://github.com/jnunemaker/flipper/pull/434).
* Improve active record idempotency (https://github.com/jnunemaker/flipper/pull/436).
* Allow customizing add actor placeholder text (https://github.com/jnunemaker/flipper/commit/5faa1e9cf66b68f8227d2f8408fb448a14676c45)

## 0.16.2

### Additions/Changes

* Bump rollout redis dependency to < 5 (https://github.com/jnunemaker/flipper/pull/403)
* Bump redis dependency to < 5 (https://github.com/jnunemaker/flipper/pull/401)
* Bump sequel dependency to < 6 (https://github.com/jnunemaker/flipper/pull/399 and https://github.com/jnunemaker/flipper/commit/edc767e69b4ce8daead9801f38e0e8bf6b238765)

## 0.16.1

### Additions/Changes

* Add actors API endpoint (https://github.com/jnunemaker/flipper/pull/372).
* Fix rack body proxy require for those using flipper without rack  (https://github.com/jnunemaker/flipper/pull/376).
* Unescapes feature_name in FeatureNameFromRoute (https://github.com/jnunemaker/flipper/pull/377).
* Replace delete_all with destroy_all in ActiveRecord adapter (https://github.com/jnunemaker/flipper/pull/395)
* Target correct bootstrap breakpoints in flipper UI (https://github.com/jnunemaker/flipper/pull/396)

## 0.16.0

### Bug Fixes

* Support slashes in feature names (https://github.com/jnunemaker/flipper/pull/362).

### Additions/Changes

* Re-order gates for improved performance in some cases (https://github.com/jnunemaker/flipper/pull/370).
* Add Feature#exist?, DSL#exist? and Flipper#exist? (https://github.com/jnunemaker/flipper/pull/371).

## 0.15.0

* Move Flipper::UI configuration options to Flipper::UI::Configuration (https://github.com/jnunemaker/flipper/pull/345).
* Bug fix in adapter synchronizing and switched DSL#import to use Synchronizer (https://github.com/jnunemaker/flipper/pull/347).
* Fix AR adapter table name prefix/suffix bug (https://github.com/jnunemaker/flipper/pull/350).
* Allow feature names to end with "features" in UI (https://github.com/jnunemaker/flipper/pull/353).

## 0.14.0

* Changed sync_interval to be seconds instead of milliseconds.

## 0.13.0

### Additions/Changes

* Update PStore adapter to allow setting thread_safe option (https://github.com/jnunemaker/flipper/pull/334).
* Update Flipper::UI to Bootstrap 4 (https://github.com/jnunemaker/flipper/pull/336).
* Add Flipper::UI configuration to add a banner with customizeable text and background color (https://github.com/jnunemaker/flipper/pull/337).
* Add sync adapter (https://github.com/jnunemaker/flipper/pull/341).
* Make cloud use sync adapter (https://github.com/jnunemaker/flipper/pull/342). This makes local flipper operations resilient to cloud failures.

## 0.12.2

### Additions/Changes

* Improvements/fixes/examples for rollout adapter (https://github.com/jnunemaker/flipper/pull/332).

## 0.12.1

### Additions/Changes

* Added rollout adapter documentation (https://github.com/jnunemaker/flipper/pull/328).

### Bug Fixes

* Fixed ActiveRecord and Sequel adapters to include disabled features for `get_all` (https://github.com/jnunemaker/flipper/pull/327).

## 0.12

### Additions/Changes

* Added Flipper.instance= writer method for explicitly setting the default instance (https://github.com/jnunemaker/flipper/pull/309).
* Added Flipper::UI configuration instance for changing text and things (https://github.com/jnunemaker/flipper/pull/306).
* Delegate memoize= and memoizing? for Flipper and Flipper::DSL (https://github.com/jnunemaker/flipper/pull/310).
* Fixed error when enabling the same group or actor more than once (https://github.com/jnunemaker/flipper/pull/313).
* Fixed redis cache adapter key (and thus cache misses) (https://github.com/jnunemaker/flipper/pull/325).
* Added Rollout adapter to make it easy to import rollout data into Flipper (https://github.com/jnunemaker/flipper/pull/319).
* Relaxed redis gem dependency constraint to allow redis-rb 4 (https://github.com/jnunemaker/flipper/pull/317).
* Added configuration option for Flipper::UI to disable feature removal (https://github.com/jnunemaker/flipper/pull/322).

## 0.11

### Backwards Compatibility Breaks

* Set flipper from env for API and UI (https://github.com/jnunemaker/flipper/pull/223 and https://github.com/jnunemaker/flipper/pull/229). It is documented, but now the memoizing middleware requires that the SetupEnv middleware is used first, unless you are configuring a Flipper default instance.
* Drop support for Ruby 2.0 as it is end of lined (https://github.com/jnunemaker/flipper/commit/c2c81ed89938155ce91acb5173ac38580f630e3d).
* Allow unregistered groups (https://github.com/jnunemaker/flipper/pull/244). Only break in compatibility is that previously unregistered groups could not be enabled and now they can be.
* Removed support for metriks (https://github.com/jnunemaker/flipper/pull/291).

### Additions/Changes

* Use primary keys with sequel adapter (https://github.com/jnunemaker/flipper/pull/210). Should be backwards compatible, but if you want it to work this way you will need to migrate your database to the new schema.
* Add redis cache adapter (https://github.com/jnunemaker/flipper/pull/211).
* Finish API and HTTP adapter that speaks to API.
* Add flipper cloud adapter (https://github.com/jnunemaker/flipper/pull/249). Nothing to see here yet, but good stuff soon. ;)
* Add importing (https://github.com/jnunemaker/flipper/pull/251).
* Added Adapter#get_all to allow for more efficient preload_all (https://github.com/jnunemaker/flipper/pull/255).
* Added :unless option to Flipper::Middleware::Memoizer to allow skipping memoization and preloading for certain requests.
* Made it possible to instrument Flipper::Cloud (https://github.com/jnunemaker/flipper/commit/4b10e4d807772202f63881f5e2c00d11ac58481f).
* Made it possible to wrap Http adapter when using Flipper::Cloud (https://github.com/jnunemaker/flipper/commit/4b10e4d807772202f63881f5e2c00d11ac58481f).
* Instrument get_multi in instrumented adapter (https://github.com/jnunemaker/flipper/commit/951d25c5ce07d3b56b0b2337adf5f6bcbe4050e7).
* Allow instrumenting Flipper::Cloud http adapter (https://github.com/jnunemaker/flipper/pull/253).
* Add DSL#preload_all and Adapter#get_all to allow for making even more efficient loading of features (https://github.com/jnunemaker/flipper/pull/255).
* Allow setting debug output of http adapter (https://github.com/jnunemaker/flipper/pull/256 and https://github.com/jnunemaker/flipper/pull/258).
* Allow setting env key for middleware (https://github.com/jnunemaker/flipper/pull/259).
* Added ActiveSupport cache store adapter for use with Rails.cache (https://github.com/jnunemaker/flipper/pull/265 and https://github.com/jnunemaker/flipper/pull/297).
* Added support for up to 3 decimal places in percentage based rollouts (https://github.com/jnunemaker/flipper/pull/274).
* Removed Flipper::GroupNotRegistered error as it is now unused (https://github.com/jnunemaker/flipper/pull/270).
* Added get_all to all adapters (https://github.com/jnunemaker/flipper/pull/298).
* Added support for Rails 5.1 (https://github.com/jnunemaker/flipper/pull/299).
* Added Flipper default instance generation (https://github.com/jnunemaker/flipper/pull/279).

## 0.10.2

* Add Adapter#get_multi to allow for efficient loading of more than one feature at a time (https://github.com/jnunemaker/flipper/pull/198)
* Add DSL#preload for efficiently loading several features at once using get_mutli (https://github.com/jnunemaker/flipper/pull/198)
* Add :preload and :preload_all options to memoizer as a way of efficiently loading several features for a request in one network call instead of N where N is the number of features checked (https://github.com/jnunemaker/flipper/pull/198)
* Strip whitespace out of feature/actor/group values posted by UI (https://github.com/jnunemaker/flipper/pull/205)
* Fix bug with dalli adapter where deleting a feature using the UI or API was not clearing the cache in the dalli adapter which meant the feature would continue to use whatever cached enabled state was present until the TTL was hit (1cd96f6)
* Change cache keys for dalli adapter. Backwards compatible in that it will just repopulate new keys on first check with this version, but old keys are not expired, so if you used the default ttl of 0, you'll have to expire them on your own. The primary reason for the change was safer namespacing of the cache keys to avoid collisions.

## 0.10.1

* Add docker compose support for contributing
* Add sequel adapter
* Show confirmation dialog when deleting a feature in flipper-ui

## 0.10.0

* Added feature check context (https://github.com/jnunemaker/flipper/pull/158)
* Do not use mass assignment for active record adapter (https://github.com/jnunemaker/flipper/pull/171)
* Several documentation improvements
* Make Flipper::UI.app.inspect return a String (https://github.com/jnunemaker/flipper/pull/176)
* changes boolean gate route to api/v1/features/boolean (https://github.com/jnunemaker/flipper/pull/175)
* add api v1 percentage_of_actors endpoint (https://github.com/jnunemaker/flipper/pull/179)
* add api v1 percentage_of_time endpoint (https://github.com/jnunemaker/flipper/pull/180)
* add api v1 actors gate endpoint  (https://github.com/jnunemaker/flipper/pull/181)
* wait for activesupport to tell us when active record is loaded for active record adapter (https://github.com/jnunemaker/flipper/pull/192)

## 0.9.2

* GET /api/v1/features
* POST /api/v1/features - add feature endpoint
* rack-protection 2.0.0 support
* pretty rake output

## 0.9.1

* bump flipper-active_record to officially support rails 5

## 0.9.0

* Moves SharedAdapterTests module to Flipper::Test::SharedAdapterTests to avoid clobbering anything top level in apps that use Flipper
* Memoizable, Instrumented and OperationLogger now delegate any missing methods to the original adapter. This was lost with the removal of the official decorator in 0.8, but is actually useful functionality for these "wrapping" adapters.
* Instrumenting adapters is now off by default. Use Flipper::Adapters::Instrumented.new(adapter) to instrument adapters and maintain the old functionality.
* Added dalli cache adapter (https://github.com/jnunemaker/flipper/pull/132)

## 0.8

* removed Flipper::Decorator and Flipper::Adapters::Decorator in favor of just calling methods on wrapped adapter
* fix bug where certain versions of AR left off quotes for key column which caused issues with MySQL https://github.com/jnunemaker/flipper/issues/120
* fix bug where AR would store multiple gate values for percentage gates for each enable/disable and then nondeterministically pick one on read (https://github.com/jnunemaker/flipper/pull/122 and https://github.com/jnunemaker/flipper/pull/124)
* added readonly adapter (https://github.com/jnunemaker/flipper/pull/111)
* flipper groups now match for truthy values rather than explicitly only true (https://github.com/jnunemaker/flipper/issues/110)
* removed gate operation instrumentation (https://github.com/jnunemaker/flipper/commit/32f14ed1fb25c64961b23c6be3dc6773143a06c8); I don't think it was useful and never found myself instrumenting it in reality
* initial implementation of flipper api - very limited functionality right now (get/delete feature, boolean gate for feature) but more is on the way
* made it easy to remove a feature (https://github.com/jnunemaker/flipper/pull/126)
* add minitest shared tests for adapters that work the same as the shared specs for rspec (https://github.com/jnunemaker/flipper/pull/127)

## 0.7.5

* support for rails 5 beta/ rack 2 alpha
* fix uninitialized constant in rails generators
* fix adapter test for clear to ensure that feature is not deleted, only gates

## 0.7.4

* Add missing migration file to gemspec for flipper-active_record

## 0.7.3

* Add Flipper ActiveRecord adapter

## 0.7.2

* Add Flipper::UI.application_breadcrumb_href for setting breadcrumb back to original app from Flipper UI

## 0.7.1

* Fix bug where features with names that match static file routes were incorrectly routing to the file action (https://github.com/jnunemaker/flipper/issues/80)

## 0.7

* Added Flipper.groups and Flipper.group_names
* Changed percentage_of_random to percentage_of_time
* Added enable/disable convenience methods for all gates (enable_group, enable_actor, enable_percentage_of_actors, enable_percentage_of_time)
* Added value convenience methods (boolean_value, groups_value, actors_value, etc.)
* Added Feature#gate_values for getting typecast adapter gate values
* Added Feature#enabled_gates and #disabled_gates for getting the gates that are enabled/disabled for the feature
* Remove Feature#description
* Added Flipper::Adapters::PStore
* Moved memoizable decorator to instance variable storage from class level thread local stuff. Now not thread safe, but we can make a thread safe version later.

UI

* Totally new. Works like a charm.

Mongo

* Updated to latest driver (~> 2.0)

## 0.6.3

* Minor bug fixes

## 0.6.2

* Added Flipper.group_exists?

## 0.6.1

* Added statsd support for instrumentation.

## 0.4.0

* No longer use #id for detecting actors. You must now define #flipper_id on
  anything that you would like to behave as an actor.
* Strings are now used instead of Integers for Actor identifiers. More flexible
  and the only reason I used Integers was to do modulo for percentage of actors.
  Since percentage of actors now uses hashing, integer is no longer needed.
* Easy integration of instrumentation with AS::Notifications or anything similar.
* A bunch of stuff around inspecting and getting names/descriptions out of
  things to more easily figure out what is going on.
* Percentage of actors hash is now also seeded with feature name so the same
  actors don't get all features instantly.
