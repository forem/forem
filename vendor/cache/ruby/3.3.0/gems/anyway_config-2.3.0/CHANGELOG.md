# Change log

## master

## 2.3.0 (2022-03-11)

- Add ability to load configurations under specific environments in pure Ruby apps. ([@fargelus][]).

Before loading environment configurations you need to specify variable `Anyway::Settings.current_environment`. In Rails apps this variable is same as `Rails.env` value.
After adding yaml loader will try to load params under this environment.

Also required env option was added to `Anyway::Config`.

## 2.2.3 (2022-01-21)

- Fix Ruby 3.1 compatibility. ([@palkan][])

- Add ability to set default key for environmental YAML files. ([@skryukov])

Define a key for environmental yaml files to read default values from with `config.anyway_config.default_environmental_key = "default"`.
This way Anyway Config will try to read settings under the `"default"` key and then merge environmental settings into them.

## 2.2.2 (2020-10-26)

- Fixed regression introduced by the `#deep_merge!` refinement.

## 2.2.1 (2020-09-28)

- Minor fixes to the prev release.

## 2.2.0 ⛓ (2020-09-28)

- Add RBS signatures and generator. ([@palkan][])

Anyway Config now ships with the basic RBS support. To use config types with Steep, add `library "anyway_config"` to your Steepfile.

We also provide an API to generate a signature for you config class: `MyConfig.to_rbs`. You can use this method to generate a scaffold for your config class.

- Add type coercion support. ([@palkan][])

Example:

```ruby
class CoolConfig < Anyway::Config
  attr_config :port, :user

  coerce_types port: :string, user: {dob: :date}
end

ENV["COOL_USER__DOB"] = "1989-07-01"

config = CoolConfig.new({port: 8080})
config.port == "8080" #=> true
config.user["dob"] == Date.new(1989, 7, 1) #=> true
```

You can also add `.disable_auto_cast!` to your config class to disable automatic conversion.

**Warning** Now values from all sources are coerced (e.g., YAML files). That could lead to a different behaviour.

- Do not dup modules/classes passed as configuration values. ([@palkan][])

- Handle loading empty YAML config files. ([@micahlee][])

## 2.1.0 (2020-12-29)

- Drop deprecated `attr_config` instance variables support.

Config setters no longer write instance variables.

- Add `config.anyway_config.future` to allow enabling upcoming features. ([@palkan][])

For smoother upgrades, we provide a mechanism to opt-out to the new defaults beforehand.
Currently, only `:unwrap_known_environments` feature could be enabled (see below):

```ruby
config.anyway_config.future.use :unwrap_known_environments
```

- Allow to skip environment keys completely (e.g., `development:`, `test:`) in a config YML when used with Rails. In that case same config is loaded in all known environments (same mechanism as for non-Rails applications)

- Add the `known_environments` property to Anyway::Settings under Rails. Use `config.anyway_config.known_environments << "staging"` to make the gem aware of custom environments. ([@progapandist][])

- Make it possible to specify default YML configs directory. ([@palkan][])

For example:

```ruby
Anyway::Settings.default_config_path = "path/to/configs"

# or in Rails
config.anyway_config.default_config_path = Rails.root.join("my/configs")
```

## 2.0.6 (2020-07-7)

- Fix Ruby 2.7 warnings. ([@palkan][])

## 2.0.5 (2020-05-15)

- Use `YAML.load` instead of `YAML.safe_laad`. ([@palkan][])

## 2.0.4 (2020-05-15)

- Fix regression with adding `ruby-next` as a runtime dependency even for RubyGems release. ([@palkan][])

## 2.0.3 (2020-05-12)

- Enable [auto-transpiling](https://github.com/ruby-next/ruby-next#transpiled-files-vs-vcs-vs-installing-from-source) to allow installing from source. ([@palkan][])

## 2.0.2 (2020-04-24)

- Make sure configs are eager loaded in Rails when `config.eager_load = true`. ([@palkan][])

Fixes [#58](https://github.com/palkan/anyway_config/issues/58).

## 2.0.1 (2020-04-15)

- Fix loading Railtie when application has been already initialized. ([@palkan][])

Fixes [#56](https://github.com/palkan/anyway_config/issues/56).

## 2.0.0 (2020-04-14)

- Fix double `yield` in tracing for ENV loader. ([@Envek][])

## 2.0.0.rc1 (2020-03-31)

- Add predicate methods for attributes with boolean defaults. ([@palkan][])

For example:

```ruby
class MyConfig < Anyway::Config
  attr_config :key, :secret, debug: false
end

MyConfig.new.debug? #=> false
MyConfig.new(debug: true).debug? #=> true
```

- Add `Config#deconstruct_keys`. ([@palkan][])

Now you can use configs in pattern matching:

```ruby
case AWSConfig.new
in bucket:, region: "eu-west-1"
  setup_eu_storage(bucket)
in bucket:, region: "us-east-1"
  setup_us_storage(bucket)
end
```

- Add pretty_print support. ([@palkan][])

Whenever you use `pp`, the output would contain pretty formatted config information
including the sources.

Example:

```ruby
pp CoolConfig.new

# #<CoolConfig
#   config_name="cool"
#   env_prefix="COOL"
#   values:
#     port => 3334 (type=load),
#     host => "test.host" (type=yml path=./config/cool.yml),
#     user =>
#       name => "john" (type=env key=COOL_USER__NAME),
#       password => "root" (type=yml path=./config/cool.yml)>
```

- Add source tracing support. ([@palkan][])

You can get the information on where a particular parameter value came from
(which loader) through via `#to_source_trace` method:

```ruby
conf = MyConfig.new
conf.to_source_trace
# {
#  "host" => {value: "test.host", source: {type: :user, called_from: "/rails/root/config/application.rb:21"}},
#  "user" => {
#    "name" => {value: "john", source: {type: :env, key: "COOL_USER__NAME"}},
#    "password" => {value: "root", source: {type: :yml, path: "config/cool.yml"}}
#  },
#  "port" => {value: 9292, source: {type: :defaults}}
# }
```

- Change the way Rails configs autoloading works. ([@palkan][])

In Rails 6, autoloading before initialization is [deprecated](https://github.com/rails/rails/commit/3e66ba91d511158e22f90ff96b594d61f40eda01). We can still
make it work by using our own autoloading mechanism (custom Zeitwerk loader).

This forces us to use a custom directory (not `app/`) for configs required at the boot time.
By default, we put _static_ configs into `config/configs` but you can still use `app/configs` for
_dynamic_ (runtime) configs.

**NOTE:** if you used `app/configs` with 2.0.0.preX and relied on configs during initialization,
you can set static configs path to `app/configs`:

```ruby
config.anyway_config.autoload_static_config_path = "app/configs"
```

You can do this by running the generator:

```sh
rails g anyway:install --configs-path=app/configs
```

- Add Rails generators. ([@palkan][])

You can create config classes with the predefined attributes like this:

```sh
rails generate config aws access_key_id secret_access_key region
```

- **BREAKING** The accessors generated by `attr_config` are not longer `attr_accessor`-s. ([@palkan][])

You cannot rely on instance variables anymore. Instead, you can use `super` when overriding accessors or
`values[name]`:

```ruby
attr_config :host, :port, :url, :meta

# override writer to handle type coercion
def meta=(val)
  super JSON.parse(val)
end

# or override reader to handle missing values
def url
  values[:url] ||= "#{host}:#{port}"
end

# in <2.1 it's still possible to read instance variables,
# i.e. the following would also work
def url
  @url ||= "#{host}:#{port}"
end
```

**NOTE**: we still set instance variables in writers (for backward compatibility), but that would
be removed in 2.1.

- Add `Config#dig` method. ([@palkan][])

- Add ability to specify types for OptionParser options. ([@palkan][])

```ruby
describe_options(
  concurrency: {
    desc: "number of threads to use",
    type: String
  }
)
```

- Add param presence validation. ([@palkan][])

You can specify some params as required, and the validation
error would be raised if they're missing or empty (only for strings):

```ruby
class MyConfig < Anyway::Config
  attr_config :api_key, :api_secret, :debug

  required :api_key, :api_secret
end

MyConfig.new(api_secret: "") #=> raises Anyway::Config::ValidationError
```

You can change the validation behaviour by overriding the `#validate!` method in your config class.

- Validate config attribute names. ([@palkan][])

Do not allow using reserved names (`Anyway::Config` method names).
Allow only alphanumeric names (matching `/^[a-z_]([\w]+)?$/`).

- Add Loaders API. ([@palkan][])

All config sources have standardized via _loaders_ API. It's possible to define
custom loaders or change the sources order.

## 2.0.0.pre2 (2019-04-26)

- Fix bug with loading from credentials when local credentials are missing. ([@palkan][])

## 2.0.0.pre (2019-04-26)

- **BREAKING** Changed the way of providing explicit values. ([@palkan][])

```ruby
# BEFORE
Config.new(overrides: data)

# AFTER
Config.new(data)
```

- Add Railtie. ([@palkan][])

`Anyway::Railtie` provides `Anyway::Settings` access via `Rails.applicaiton.configuration.anyway_config`.

It also adds `app/configs` path to autoload paths (low-level, `ActiveSupport::Dependencies`) to
make it possible to use configs in the app configuration files.

- Add test helpers. ([@palkan][])

Added `with_env` helper to test code in the context of the specified
environment variables.

Included automatically in RSpec for examples with the `type: :config` meta
or with the `spec/configs` path.

- Add support for _local_ files. ([@palkan][])

Now users can store their personal configurations in _local_ files:

- `<config_name>.local.yml`
- `config/credentials/local.yml.enc` (for Rails 6).

Local configs are meant for using in development and only loaded if
`Anyway::Settings.use_local_files` is `true` (which is true by default if
`RACK_ENV` or `RAILS_ENV` env variable is equal to `"development"`).

- Add Rails credentials support. ([@palkan][])

The data from credentials is loaded after the data from YAML config and secrets,
but before environmental variables (i.e. env variables are _stronger_)

- Update config name inference logic. ([@palkan][])

Config name is automatically inferred only if:

- the class name has a form of `<Module>::Config` (`SomeModule::Config => "some_module"`)
- the class name has a form of `<Something>Config` (`SomeConfig => "some"`)

- Fix config classes inheritance. ([@palkan][])

Previously, inheritance didn't work due to the lack of proper handling of class-level
configuration (naming, option parses settings, defaults).

Now it's possible to extend config classes without breaking the original classes functionality.

- **Require Ruby >= 2.5.0.**

## 1.4.3 (2019-02-04)

- Add a temporary fix for JRuby regression [#5550](https://github.com/jruby/jruby/issues/5550). ([@palkan][])

## 1.4.2 (2018-01-05)

- Fix: detect Rails by presence of `Rails::VERSION` (instead of just `Rails`). ([@palkan][])

## 1.4.1 (2018-10-30)

- Add `.flag_options` to mark some params as flags (value-less) for OptionParse. ([@palkan][])

## 1.4.0 (2018-10-29)

- Add OptionParse integration ([@jastkand][])

See more [PR#18](https://github.com/palkan/anyway_config/pull/18).

- Use underscored config name as an env prefix. ([@palkan][])

For a config class:

```ruby
class MyApp < Anyway::Config
end
```

Before this change we use `MYAPP_` prefix, now it's `MY_APP_`.

You can specify the prefix explicitly:

```ruby
class MyApp < Anyway::Config
  env_prefix "MYAPP_"
end
```

## 1.3.0 (2018-06-15)

- Ruby 2.2 is no longer supported.

- `Anyway::Config.env_prefix` method is introduced. ([@charlie-wasp][])

## 1.2.0 (2018-02-19)

Now works on JRuby 9.1+.

## 1.1.3 (2017-12-20)

- Allow to pass raw hash with explicit values to `Config.new`. ([@dsalahutdinov][])

Example:

```ruby
Sniffer::Config.new(
  overrides: {
    enabled: true,
    storage: {capacity: 500}
  }
)
```

See more [PR#10](https://github.com/palkan/anyway_config/pull/10).

## 1.1.2 (2017-11-19)

- Enable aliases for YAML. ([@onemanstartup][])

## 1.1.1 (2017-10-21)

- Return deep duplicate of a Hash in `Env#fetch`. ([@palkan][])

## 1.1.0 (2017-10-06)

- Add `#to_h` method. ([@palkan][])

See [#4](https://github.com/palkan/anyway_config/issues/4).

- Make it possible to extend configuration parameters. ([@palkan][])

## 1.0.0 (2017-06-20)

- Lazy load and parse ENV configuration. ([@palkan][])

- Add support for ERB in YML configuration. ([@palkan][])

## 0.5.0 (2017-01-20)

- Drop `active_support` dependency. ([@palkan][])

Use custom refinements instead of requiring `active_support`.

No we're dependency-free!

## 0.1.0 (2015-01-20)

- Initial version.

[@palkan]: https://github.com/palkan
[@onemanstartup]: https://github.com/onemanstartup
[@dsalahutdinov]: https://github.com/dsalahutdinov
[@charlie-wasp]: https://github.com/charlie-wasp
[@jastkand]: https://github.com/jastkand
[@envek]: https://github.com/Envek
[@progapandist]: https://github.com/progapandist
[@skryukov]: https://github.com/skryukov
[@fargelus]: https://github.com/fargelus
