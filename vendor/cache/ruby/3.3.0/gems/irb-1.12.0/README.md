# IRB

[![Gem Version](https://badge.fury.io/rb/irb.svg)](https://badge.fury.io/rb/irb)
[![build](https://github.com/ruby/irb/actions/workflows/test.yml/badge.svg)](https://github.com/ruby/irb/actions/workflows/test.yml)

IRB stands for "interactive Ruby" and is a tool to interactively execute Ruby expressions read from the standard input.

The `irb` command from your shell will start the interpreter.

- [Installation](#installation)
- [Usage](#usage)
  - [The `irb` Executable](#the-irb-executable)
  - [The `binding.irb` Breakpoint](#the-bindingirb-breakpoint)
- [Commands](#commands)
- [Debugging with IRB](#debugging-with-irb)
  - [More about `debug.gem`](#more-about-debuggem)
  - [Advantages Over `debug.gem`'s Console](#advantages-over-debuggems-console)
- [Type Based Completion](#type-based-completion)
  - [How to Enable IRB::TypeCompletor](#how-to-enable-irbtypecompletor)
  - [Advantage over Default IRB::RegexpCompletor](#advantage-over-default-irbregexpcompletor)
  - [Difference between Steep's Completion](#difference-between-steeps-completion)
- [Configuration](#configuration)
  - [Environment Variables](#environment-variables)
- [Documentation](#documentation)
- [Extending IRB](#extending-irb)
- [Development](#development)
- [Contributing](#contributing)
- [Releasing](#releasing)
- [License](#license)

## Installation

> [!Note]
>
> IRB is a default gem of Ruby so you shouldn't need to install it separately.
>
> But if you're using Ruby 2.6 or later and want to upgrade/install a specific version of IRB, please follow these steps.

To install it with `bundler`, add this line to your application's Gemfile:

```ruby
gem 'irb'
```

And then execute:

```shell
$ bundle
```

Or install it directly with:

```shell
$ gem install irb
```

## Usage

> [!Note]
>
> We're working hard to match Pry's variety of powerful features in IRB, and you can track our progress or find contribution ideas in [this document](https://github.com/ruby/irb/blob/master/COMPARED_WITH_PRY.md).

### The `irb` Executable

You can start a fresh IRB session by typing `irb` in your terminal.

In the session, you can evaluate Ruby expressions or even prototype a small Ruby script. An input is executed when it is syntactically complete.

```shell
$ irb
irb(main):001> 1 + 2
=> 3
irb(main):002* class Foo
irb(main):003*   def foo
irb(main):004*     puts 1
irb(main):005*   end
irb(main):006> end
=> :foo
irb(main):007> Foo.new.foo
1
=> nil
```

### The `binding.irb` Breakpoint

If you use Ruby 2.5 or later versions, you can also use `binding.irb` in your program as breakpoints.

Once a `binding.irb` is evaluated, a new IRB session will be started with the surrounding context:

```shell
$ ruby test.rb

From: test.rb @ line 2 :

    1: def greet(word)
 => 2:   binding.irb
    3:   puts "Hello #{word}"
    4: end
    5:
    6: greet("World")

irb(main):001:0> word
=> "World"
irb(main):002:0> exit
Hello World
```

## Commands

The following commands are available on IRB. You can get the same output from the `help` command.

```txt
Help
  help           List all available commands. Use `help <command>` to get information about a specific command.

IRB
  exit           Exit the current irb session.
  exit!          Exit the current process.
  irb_load       Load a Ruby file.
  irb_require    Require a Ruby file.
  source         Loads a given file in the current session.
  irb_info       Show information about IRB.
  history        Shows the input history. `-g [query]` or `-G [query]` allows you to filter the output.

Workspace
  cwws           Show the current workspace.
  chws           Change the current workspace to an object.
  workspaces     Show workspaces.
  pushws         Push an object to the workspace stack.
  popws          Pop a workspace from the workspace stack.

Multi-irb (DEPRECATED)
  irb            Start a child IRB.
  jobs           List of current sessions.
  fg             Switches to the session of the given number.
  kill           Kills the session with the given number.

Debugging
  debug          Start the debugger of debug.gem.
  break          Start the debugger of debug.gem and run its `break` command.
  catch          Start the debugger of debug.gem and run its `catch` command.
  next           Start the debugger of debug.gem and run its `next` command.
  delete         Start the debugger of debug.gem and run its `delete` command.
  step           Start the debugger of debug.gem and run its `step` command.
  continue       Start the debugger of debug.gem and run its `continue` command.
  finish         Start the debugger of debug.gem and run its `finish` command.
  backtrace      Start the debugger of debug.gem and run its `backtrace` command.
  info           Start the debugger of debug.gem and run its `info` command.

Misc
  edit           Open a file or source location.
  measure        `measure` enables the mode to measure processing time. `measure :off` disables it.

Context
  show_doc       Enter the mode to look up RI documents.
  ls             Show methods, constants, and variables.
  show_source    Show the source code of a given method or constant.
  whereami       Show the source code around binding.irb again.

Aliases
  $              Alias for `show_source`
  @              Alias for `whereami`
```

## Debugging with IRB

Starting from version 1.8.0, IRB boasts a powerful integration with `debug.gem`, providing a debugging experience akin to `pry-byebug`.

After hitting a `binding.irb` breakpoint, you can activate the debugger with the `debug` command. Alternatively, if the `debug` method happens to already be defined in the current scope, you can call `irb_debug`.

```shell
From: test.rb @ line 3 :

    1:
    2: def greet(word)
 => 3:   binding.irb
    4:   puts "Hello #{word}"
    5: end
    6:
    7: greet("World")

irb(main):001> debug
irb:rdbg(main):002>
```

Once activated, the prompt's header changes from `irb` to `irb:rdbg`, enabling you to use any of `debug.gem`'s [commands](https://github.com/ruby/debug#debug-command-on-the-debug-console):

```shell
irb:rdbg(main):002> info # use info command to see available variables
%self = main
_ = nil
word = "World"
irb:rdbg(main):003> next # use next command to move to the next line
[1, 7] in test.rb
     1|
     2| def greet(word)
     3|   binding.irb
=>   4|   puts "Hello #{word}"
     5| end
     6|
     7| greet("World")
=>#0    Object#greet(word="World") at test.rb:4
  #1    <main> at test.rb:7
irb:rdbg(main):004>
```

Simultaneously, you maintain access to IRB's commands, such as `show_source`:

```shell
irb:rdbg(main):004> show_source greet

From: test.rb:2

def greet(word)
  binding.irb
  puts "Hello #{word}"
end
```

### More about `debug.gem`

`debug.gem` offers many advanced debugging features that simple REPLs can't provide, including:

- Step-debugging
- Frame navigation
- Setting breakpoints with commands
- Thread control
- ...and many more

To learn about these features, please refer to `debug.gem`'s [commands list](https://github.com/ruby/debug#debug-command-on-the-debug-console).

In the `irb:rdbg` session, the `help` command will also display all commands from `debug.gem`.

### Advantages Over `debug.gem`'s Console

This integration offers several benefits over `debug.gem`'s native console:

1. Access to handy IRB commands like `show_source` or `show_doc`.
2. Support for multi-line input.
3. Symbol shortcuts such as `@` (`whereami`) and `$` (`show_source`).
4. Autocompletion.
5. Customizable prompt.

However, there are also some limitations to be aware of:

1. `binding.irb` doesn't support `pre` and `do` arguments like [`binding.break`](https://github.com/ruby/debug#bindingbreak-method).
2. As IRB [doesn't currently support remote-connection](https://github.com/ruby/irb/issues/672), it can't be used with `debug.gem`'s remote debugging feature.
3. Access to the previous return value via the underscore `_` is not supported.

## Type Based Completion

IRB's default completion `IRB::RegexpCompletor` uses Regexp. IRB has another experimental completion `IRB::TypeCompletor` that uses type analysis.

### How to Enable IRB::TypeCompletor

Install [ruby/repl_type_completor](https://github.com/ruby/repl_type_completor/) with:
```
$ gem install repl_type_completor
```
Or add these lines to your project's Gemfile.
```ruby
gem 'irb'
gem 'repl_type_completor', group: [:development, :test]
```

Now you can use type based completion by:

Running IRB with the `--type-completor` option
```
$ irb --type-completor
```

Or writing this line to IRB's rc-file (e.g. `~/.irbrc`)
```ruby
IRB.conf[:COMPLETOR] = :type # default is :regexp
```

Or setting the environment variable `IRB_COMPLETOR`
```ruby
ENV['IRB_COMPLETOR'] = 'type'
IRB.start
```

To check if it's enabled, type `irb_info` into IRB and see the `Completion` section.
```
irb(main):001> irb_info
...
# Enabled
Completion: Autocomplete, ReplTypeCompletor: 0.1.0, Prism: 0.18.0, RBS: 3.3.0
# Not enabled
Completion: Autocomplete, RegexpCompletor
...
```
If you have `sig/` directory or `rbs_collection.lock.yaml` in current directory, IRB will load it.

### Advantage over Default IRB::RegexpCompletor

IRB::TypeCompletor can autocomplete chained methods, block parameters and more if type information is available.
These are some examples IRB::RegexpCompletor cannot complete.

```ruby
irb(main):001> 'Ruby'.upcase.chars.s # Array methods (sample, select, shift, size)
```

```ruby
irb(main):001> 10.times.map(&:to_s).each do |s|
irb(main):002>   s.up # String methods (upcase, upcase!, upto)
```

```ruby
irb(main):001> class User < ApplicationRecord
irb(main):002>   def foo
irb(main):003>     sa # save, save!
```

As a trade-off, completion calculation takes more time than IRB::RegexpCompletor.

### Difference between Steep's Completion

Compared with Steep, IRB::TypeCompletor has some difference and limitations.
```ruby
[0, 'a'].sample.
# Steep completes intersection of Integer methods and String methods
# IRB::TypeCompletor completes both Integer and String methods
```

Some features like type narrowing is not implemented.
```ruby
def f(arg = [0, 'a'].sample)
  if arg.is_a?(String)
    arg. # Completes both Integer and String methods
```

Unlike other static type checker, IRB::TypeCompletor uses runtime information to provide better completion.
```ruby
irb(main):001> a = [1]
=> [1]
irb(main):002> a.first. # Completes Integer methods
```

## Configuration

### Environment Variables

- `NO_COLOR`: Assigning a value to it disables IRB's colorization.
- `IRB_USE_AUTOCOMPLETE`: Setting it to `false` disables IRB's autocompletion.
- `IRB_COMPLETOR`: Configures IRB's auto-completion behavior, allowing settings for either `regexp` or `type`.
- `VISUAL`: Its value would be used to open files by the `edit` command.
- `EDITOR`: Its value would be used to open files by the `edit` command if `VISUAL` is unset.
- `IRBRC`: The file specified would be evaluated as IRB's rc-file.

## Documentation

https://docs.ruby-lang.org/en/master/IRB.html

## Extending IRB

IRB is currently going through some refactoring to bring in some cool improvements and make things more flexible for developers.
We know that in the past, due to a lack of public APIs and documentation, many of you have had to use IRB's private APIs
and components to extend it. We also know that changes can be a bit annoying and might mess with your current setup.

We're sorry if this causes a bit of a scramble. We're working hard to make IRB better and your input is super important to us.
If you've been using private APIs or components in your projects, we'd love to hear about your use cases. Please feel free to file a new issue. Your feedback will be a massive help in guiding us on how to design and prioritize the development of official APIs in the future.

Right now, we've got command extension APIs on the drawing board, as you can see in [#513](https://github.com/ruby/irb/issues/513).
We've also got a prototype for helper method extension APIs in the works, as shown in [#588](https://github.com/ruby/irb/issues/588).

We really appreciate your understanding and patience during this transition. We're pretty excited about the improvements these changes will bring to the IRB ecosystem and we hope you are too!

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ruby/irb.

### Set up the environment

1. Fork the project to your GithHub account
2. Clone the fork with `git clone git@github.com:[your_username]/irb.git`
3. Run `bundle install`
4. Run `bundle exec rake` to make sure tests pass locally

### Run integration tests

If your changes affect component rendering, such as the autocompletion's dialog/dropdown, you may need to run IRB's integration tests, known as `yamatanooroti`.

Before running these tests, ensure that you have `libvterm` installed. If you're using Homebrew, you can install it by running:

```bash
brew install libvterm
```

After installing `libvterm`, you can run the integration tests using the following commands:

```bash
WITH_VTERM=1 bundle install
WITH_VTERM=1 bundle exec rake test test_yamatanooroti
```

## Releasing

```
rake release
gh release create vX.Y.Z --generate-notes
```

## License

The gem is available as open source under the terms of the [2-Clause BSD License](https://opensource.org/licenses/BSD-2-Clause).
