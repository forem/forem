# Guard::RSpec

[![Gem Version](https://badge.fury.io/rb/guard-rspec.png)](http://badge.fury.io/rb/guard-rspec) [![Build Status](https://secure.travis-ci.org/guard/guard-rspec.png?branch=master)](http://travis-ci.org/guard/guard-rspec) [![Dependency Status](https://gemnasium.com/guard/guard-rspec.png)](https://gemnasium.com/guard/guard-rspec) [![Code Climate](https://codeclimate.com/github/guard/guard-rspec.png)](https://codeclimate.com/github/guard/guard-rspec) [![Coverage Status](https://coveralls.io/repos/guard/guard-rspec/badge.png?branch=master)](https://coveralls.io/r/guard/guard-rspec)

Guard::RSpec allows to automatically & intelligently launch specs when files are modified.

* Compatible with RSpec >2.99 & 3
* Tested against Ruby 2.2.x, JRuby 9.0.5.0 ~~and Rubinius~~.

## Install

Add the gem to your Gemfile (inside development group):

``` ruby
 gem 'guard-rspec', require: false
```

Add guard definition to your Guardfile by running this command:

```
$ bundle exec guard init rspec
```

## Installing with beta versions of RSpec

To install beta versions of RSpec, you need to set versions of all the dependencies, e.g:

```ruby
gem 'rspec', '= 3.5.0.beta3'
gem 'rspec-core', '= 3.5.0.beta3'
gem 'rspec-expectations', '= 3.5.0.beta3'
gem 'rspec-mocks', '= 3.5.0.beta3'
gem 'rspec-support', '= 3.5.0.beta3'

gem 'guard-rspec', '~> 4.7'
```

and for Rails projects this also means adding:

```ruby
gem 'rspec-rails', '= 3.5.0.beta3'
```

and then running `bundle update rspec rspec-core rspec-expectations rspec-mocks rspec-support rspec-rails` or just `bundle update` to update all the gems in your project.

## Usage

Please read [Guard usage doc](https://github.com/guard/guard#readme).

## Guardfile

Guard::RSpec can be adapted to all kinds of projects, some examples:

### Standard RubyGem project

``` ruby
guard :rspec, cmd: 'rspec' do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^lib/(.+)\.rb$})     { |m| "spec/lib/#{m[1]}_spec.rb" }
  watch('spec/spec_helper.rb')  { "spec" }
end
```

### Typical Rails app

``` ruby
guard :rspec, cmd: 'bundle exec rspec' do
  watch('spec/spec_helper.rb')                        { "spec" }
  watch('config/routes.rb')                           { "spec/routing" }
  watch('app/controllers/application_controller.rb')  { "spec/controllers" }
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^app/(.+)\.rb$})                           { |m| "spec/#{m[1]}_spec.rb" }
  watch(%r{^app/(.*)(\.erb|\.haml|\.slim)$})          { |m| "spec/#{m[1]}#{m[2]}_spec.rb" }
  watch(%r{^lib/(.+)\.rb$})                           { |m| "spec/lib/#{m[1]}_spec.rb" }
  watch(%r{^app/controllers/(.+)_(controller)\.rb$})  { |m| ["spec/routing/#{m[1]}_routing_spec.rb", "spec/#{m[2]}s/#{m[1]}_#{m[2]}_spec.rb", "spec/acceptance/#{m[1]}_spec.rb"] }
end
```

Please read [Guard doc](https://github.com/guard/guard#readme) for more information about the Guardfile DSL.

## Options

Guard::RSpec 4.0 now uses a simpler approach with the new `cmd` option that let you precisely define which rspec command will be launched on each run. **This option is required** due to the number of different ways possible to invoke rspec, the template now includes a default that should work for most applications but may not be optimal for all. As example if you want to support Spring with a custom formatter (progress by default) use:

``` ruby
guard :rspec, cmd: 'spring rspec -f doc' do
  # ...
end
```

NOTE: the above example assumes you have the `spring rspec` command installed - see here: https://github.com/jonleighton/spring-commands-rspec

### Running with bundler

Running `bundle exec guard` will not run the specs with bundler. You need to change the `cmd` option to `bundle exec rspec`:

``` ruby
guard :rspec, cmd: 'bundle exec rspec' do
  # ...
end
```

### List of available options:

``` ruby
cmd: 'zeus rspec'      # Specify a custom rspec command to run, default: 'rspec'
cmd_additional_args: '-f progress' # Any arguments that should be added after the default
                                   # arguments are applied but before the spec list
spec_paths: ['spec']   # Specify a custom array of paths that contain spec files
failed_mode: :focus    # What to do with failed specs
                       # Available values:
                       #  :focus - focus on the first 10 failed specs, rerun till they pass
                       #  :keep - keep failed specs until they pass (add them to new ones)
                       #  :none (default) - just report
all_after_pass: true   # Run all specs after changed specs pass, default: false
all_on_start: true     # Run all the specs at startup, default: false
launchy: nil           # Pass a path to an rspec results file, e.g. ./tmp/spec_results.html
notification: false    # Display notification after the specs are done running, default: true
run_all: { cmd: 'custom rspec command', message: 'custom message' } # Custom options to use when running all specs
title: 'My project'    # Display a custom title for the notification, default: 'RSpec results'
chdir: 'directory'     # run rspec from within a given subdirectory (useful if project has separate specs for submodules)
results_file: 'some/path' # use the given file for storing results (instead of default relative path)
bundler_env: :original_env # Specify which Bundler env to run the cmd under, default: :original_env
                       # Available values:
                       #  :clean_env - old behavior, uses Bundler environment with all bundler-related variables removed. This is deprecated in bundler 1.12.x.
                       #  :original_env (default) - uses Bundler environment present before Bundler was activated
                       #  :inherit - runs inside the current environment
```

### Using Launchy to view rspec results

guard-rspec can be configured to launch a results file in lieu of outputing rspec results to the terminal.
Configure your Guardfile with the launchy option:

``` ruby
guard :rspec, cmd: 'rspec -f html -o ./tmp/spec_results.html', launchy: './tmp/spec_results.html' do
  # ...
end
```

### Zeus Integration

You can use plain `Zeus` or you can use `Guard::Zeus` for managing the `Zeus` server (but you'll want to remove the spec watchers from `Guard::Zeus`, or you'll have tests running multiple times).

Also, if you get warnings about empty environment, be sure to [read about this workaround](https://github.com/guard/guard-rspec/wiki/Warning:-no-environment)

### Using parallel_tests

parallel_tests has a `-o` option for passing RSpec options, and here's a trick to make it work with Guard::RSpec:

```ruby
rspec_options = {
  cmd: "bundle exec rspec",
  run_all: {
    cmd: "bundle exec parallel_rspec -o '",
    cmd_additional_args: "'"
  }
}
guard :rspec, rspec_options do
# (...)
```

(Notice where the `'` characters are placed)


## Development

* Documentation hosted at [RubyDoc](http://rubydoc.info/github/guard/guard-rspec/master/frames).
* Source hosted at [GitHub](https://github.com/guard/guard-rspec).

Pull requests are very welcome! Please try to follow these simple rules if applicable:

* Please create a topic branch for every separate change you make.
* Make sure your patches are well tested. All specs run with `rake spec:portability` must pass.
* Update the [README](https://github.com/guard/guard-rspec/blob/master/README.md).
* Please **do not change** the version number.

For questions please join us in our [Google group](http://groups.google.com/group/guard-dev) or on
`#guard` (irc.freenode.net).

### Author

[Thibaud Guillaume-Gentil](https://github.com/thibaudgg) ([@thibaudgg](https://twitter.com/thibaudgg))

### Contributors

[https://github.com/guard/guard-rspec/contributors](https://github.com/guard/guard-rspec/contributors)
