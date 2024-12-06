# YARD ActiveSupport::Concern Plugin

[![Version](http://img.shields.io/gem/v/yard-activesupport-concern.svg?style=flat-square)](https://rubygems.org/gems/yard-activesupport-concern)
[![Downloads](http://img.shields.io/gem/dt/yard-activesupport-concern.svg?style=flat-square)](https://rubygems.org/gems/yard-activesupport-concern)
[![Open Github issues](http://img.shields.io/github/issues/digitalcuisine/yard-activesupport-concern.svg?style=flat-square)](https://github.com/digitalcuisine/yard-activesupport-concern/issues)

This is a [YARD](https://github.com/lsegal/yard) extension that brings support for modules making use of `ActiveSupport::Concern` (very frequent in Rails projects). Here's an example of such module:

```ruby
module M
  extend ActiveSupport::Concern

  included do
    # @!method disabled
    # @!scope class
    # @return [Collection<Model>] Return a scope to get all disabled records
    scope :disabled, -> { where(disabled: true) }
  end

  class_methods do
    # A quick way to get all published records
    # @return [Collection<Model>] Return a scope to get all published records
    def published
      where(published: true)
    end
  end
end
```

Because `ActiveSupport::Concern` moves method/attributes/... definitions inside `included` or `class_methods` blocks, YARD cannot document them out of the box. As a result, the docstrings in the above example won't show in the generated documentation.  
For many, one workaround has been to move all comments above the `included` or `class_methods` blocks. But this decouples the comments from the actual method definitions and hence defeats the purpose of commenting your code.

This plugin is here to set this right and make YARD aware of those nested definitions.

## Installation

Add the following line to your Gemfile:

```ruby
gem 'yard-activesupport-concern'
```

Or install the gem globally:

`gem install yard-activesupport-concern`

You can then use the plugin using the `--plugin activesupport-concern` command-line option or by instructing YARD to always load all available plugins: `yard config load_plugins true` (see [the docs](http://www.rubydoc.info/gems/yard/YARD/Config#load_plugins-class_method))

If you're using a `.yardopts` file, just add the `--plugin activesupport-concern` option to it.

That's it!


## License

This plugin is released under the MIT license. Please refer to the [LICENSE](https://github.com/digitalcuisine/yard-activesupport-concern/blob/master/LICENSE) file.


## Contributing

Please refer to Github's [guide](https://guides.github.com/activities/contributing-to-open-source/#contributing) to efficiently contribute to this project!
