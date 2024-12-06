# Official Ruby-on-Rails Integration with Sass

This gem provides official integration for Ruby on Rails projects with the Sass stylesheet language.

## Installing

Since Rails 3.1, new Rails projects will be already configured to use Sass. If you are upgrading to Rails 3.1 you will need to add the following to your Gemfile:

```ruby
gem 'sass-rails'
```

## Configuration

To configure Sass via Rails set use `config.sass` in your
application and/or environment files to set configuration
properties that will be passed to Sass.

### Options

- `preferred_syntax` - This option determines the default Sass syntax and file extensions that will be used by Rails generators. Can be `:scss` (default CSS-compatible SCSS syntax) or `:sass` (indented Sass syntax).

The [list of supported Sass options](http://sass-lang.com/docs/yardoc/file.SASS_REFERENCE.html#options)
can be found on the Sass Website with the following caveats:

- `:style` - This option is not supported. This is determined by the Rails environment. It's `:expanded` only on development, otherwise it's `:compressed`.
- `:never_update` - This option is not supported. Instead set `config.assets.enabled = false`
- `:always_update` - This option is not supported. Sprockets uses a controller to access stylesheets in development mode instead of a full scan for changed files.
- `:always_check` - This option is not supported. Sprockets always checks in development.
- `:syntax` - This is determined by the file's extensions.
- `:filename` - This is determined by the file's name.
- `:line` - This is provided by the template handler.

### Example
```ruby
MyProject::Application.configure do
  config.sass.preferred_syntax = :sass
  config.sass.line_comments = false
  config.sass.cache = false
end
```

## Important Note

Sprockets provides some directives that are placed inside of comments called `require`, `require_tree`, and
`require_self`. **<span style="color:#c00">DO NOT USE THEM IN YOUR SASS/SCSS FILES.</span>** They are very
primitive and do not work well with Sass files. Instead, use Sass's native `@import` directive which
`sass-rails` has customized to integrate with the conventions of your Rails projects.

## Features

### Glob Imports

When in Rails, there is a special import syntax that allows you to
glob imports relative to the folder of the stylesheet that is doing the importing.

* `@import "mixins/*"` will import all the files in the mixins folder
* `@import "mixins/**/*"` will import all the files in the mixins tree

Any valid ruby glob may be used. The imports are sorted alphabetically.

**NOTE:** It is recommended that you only use this when importing pure library
files (containing mixins and variables) because it is difficult to control the
cascade ordering for imports that contain styles using this approach.

### Asset Helpers
When using the asset pipeline, paths to assets must be rewritten.
When referencing assets use the following asset helpers (underscored in Ruby, hyphenated
in Sass):

#### `asset-path($relative-asset-path)`
Returns a string to the asset.

* `asset-path("rails.png")` returns `"/assets/rails.png"`

#### `asset-url($relative-asset-path)`
Returns a url reference to the asset.

* `asset-url("rails.png")` returns `url(/assets/rails.png)`

As a convenience, for each of the following asset classes there are
corresponding `-path` and `-url` helpers:
image, font, video, audio, javascript, stylesheet.

* `image-path("rails.png")` returns `"/assets/rails.png"`
* `image-url("rails.png")` returns `url(/assets/rails.png)`

#### `asset-data-url($relative-asset-path)`
Returns a url reference to the Base64-encoded asset at the specified path.

* `asset-data-url("rails.png")` returns `url(data:image/png;base64,iVBORw0K...)`

## Running Tests

    $ bundle install
    $ bundle exec rake test

If you need to test against local gems, use Bundler's gem :path option in the Gemfile and also edit `test/support/test_helper.rb` and tell the tests where the gem is checked out.

## Code Status

* [![Travis CI](https://api.travis-ci.org/rails/sass-rails.svg)](http://travis-ci.org/rails/sass-rails)
* [![Gem Version](https://badge.fury.io/rb/sass-rails.svg)](http://badge.fury.io/rb/sass-rails)
