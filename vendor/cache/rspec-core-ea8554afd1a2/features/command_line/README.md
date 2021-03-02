The `rspec` command comes with several options you can use to customize RSpec's
behavior, including output formats, filtering examples, etc.

For a full list of options, run the `rspec` command with the `--help` flag:

```ruby
$ rspec --help
```

### Run with `ruby`

Generally, life is simpler if you just use the `rspec` command. If you must use
the `ruby` command, however, you'll need to require `rspec/autorun`. You can
either pass a `-rrspec/autorun` CLI option when invoking `ruby`, or add a
`require 'rspec/autorun'` to one or more of your spec files.

It is conventional to put configuration in and require assorted support files
from `spec/spec_helper.rb`. It is also conventional to require that file from
the spec files using `require 'spec_helper'`. This works because RSpec
implicitly adds the `spec` directory to the `LOAD_PATH`. It also adds `lib`, so
your implementation files will be on the `LOAD_PATH` as well.

If you're using the `ruby` command, you'll need to do this yourself (with the
`-I` option). Putting these together, your command might be something like this:

```ruby
$ ruby -Ilib -Ispec -rrspec/autorun path/to/spec.rb
```
