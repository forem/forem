# Filtering

RSpec supports filtering examples and example groups in multiple ways,
allowing you to run a targeted subset of your suite that you are
currently interested in.

## Filtering by Tag

Examples and groups can be filtered by matching tags declared on
the command line or options files, or filters declared via
`RSpec.configure`, with hash key/values submitted within example group
and/or example declarations. For example, given this declaration:

``` ruby
RSpec.describe Thing, :awesome => true do
  it "does something" do
    # ...
  end
end
```

That group (or any other with `:awesome => true`) would be filtered in
with any of the following commands:

    rspec --tag awesome:true
    rspec --tag awesome
    rspec -t awesome:true
    rspec -t awesome

Prefixing the tag names with `~` negates the tags, thus excluding this
group with any of:

    rspec --tag ~awesome:true
    rspec --tag ~awesome
    rspec -t ~awesome:true
    rspec -t ~awesome

## Filtering by Example description

RSpec provides the `--example` (short form: `-e`) option to allow you to
select examples or groups by their description. All loaded examples
whose full description (computed based on the description of the example
plus that of all ancestor groups) contains the provided argument will be
executed.

    rspec --example "Homepage when logged in"
    rspec -e "Homepage when logged in"

You can specify this option multiple times to select multiple sets of examples:

    rspec -e "Homepage when logged in" -e "User"

Note that RSpec will load all spec files in these situations, which can
incur considerable start-up costs (particularly for Rails apps). If you
know that the examples you are targeting are in particular files, you can
also pass the file or directory name so that RSpec loads only those spec
files, speeding things up:

    rspec spec/homepage_spec.rb -e "Homepage when logged in"
    rspec -e "Homepage when logged in" spec/homepage_spec.rb

Note also that description-less examples that have generated descriptions
(typical when using the one-liner syntax) cannot be directly filtered with
this option, because it is necessary to execute the example to generate the
description, so RSpec is unable to use the not-yet-generated description to
decide whether or not to execute an example. You can, of course, pass part
of a group's description to select all examples defined in the group
(including those that have no description).

## Filtering by Example Location

Examples and groups can be selected from the command line by passing the
file and line number where they are defined, separated by a colon:

    rspec spec/homepage_spec.rb:14 spec/widgets_spec.rb:40 spec/users_spec.rb

This command would run the example or group defined on line 14 of
`spec/homepage_spec.rb`, the example or group defined on line 40 of
`spec/widgets_spec.rb`, and all examples and groups defined in
`spec/users_spec.rb`.

If there is no example or group defined at the specified line, RSpec
will run the last example or group defined before the line.

## Focusing

RSpec supports configuration options that make it easy to select
examples by temporarily tweaking them. In your `spec_helper.rb` (or
a similar file), put this configuration:

``` ruby
RSpec.configure do |config|
  config.filter_run_when_matching :focus
end
```

This configuration is generated for you by `rspec --init` in the
commented-out section of recommendations. With that in place, you
can tag any example group or example with `:focus` metadata to
select it:

``` ruby
it "does something" do
# becomes...
it "does something", :focus do
```

RSpec also ships with aliases of the common example group definition
methods (`describe`, `context`) and example methods (`it`, `specify`,
`example`) with an `f` prefix that automatically includes `:focus =>
true` metadata, allowing you to easily change `it` to `fit` (think
"focused it"), `describe` to `fdescribe`, etc in order to temporarily
focus them.

## Options files and command line overrides

Command line option declarations can be stored in `.rspec`, `~/.rspec`,
`$XDG_CONFIG_HOME/rspec/options` or a custom options file. This is useful for
storing defaults. For example, let's say you've got some slow specs that you
want to suppress most of the time. You can tag them like this:

``` ruby
RSpec.describe Something, :slow => true do
```

And then store this in `.rspec`:

    --tag ~slow:true

Now when you run `rspec`, that group will be excluded.

## Overriding

Of course, you probably want to run them sometimes, so you can override
this tag on the command line like this:

    rspec --tag slow:true

## Precedence

Location and description filters have priority over tag filters since
they express a desire by the user to run specific examples. Thus, you
could specify a location or description at the command line to run an
example or example group that would normally be excluded due to a
`:slow` tag if you were using the above configuration.

## RSpec.configure

You can also store default tags with `RSpec.configure`. We use `tag` on
the command line (and in options files like `.rspec`), but for historical
reasons we use the term `filter` in `RSpec.configure`:

``` ruby
RSpec.configure do |c|
  c.filter_run_including :foo => :bar
  c.filter_run_excluding :foo => :bar
end
```

These declarations can also be overridden from the command line.

## Silencing filter announcements

By default, RSpec will print a message before your specs run indicating what filters are configured, for instance, it might print "Run options: include {:focus=>true}" if you set `config.filter_run_including :focus => true`.

If you wish to prevent those messages from appearing in your spec output, you can set the `silence_filter_announcements` config setting to `true` like this:

``` ruby
RSpec.configure do |c|
  c.filter_run_including :foo => :bar
  c.silence_filter_announcements = true
end
```
