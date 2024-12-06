# Shellany

Shellany captures command output.

## Features:

- portability (should work on recent JRuby versions)
- capturing stdout, stderr in a convenient way
- returning the result in a convenient way
- detecting if a shell is needed (though incomplete/primitive implementation)
- prevents running the same command multiple times

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'shellany'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install shellany

## Usage

Basic usage:

```ruby
require 'shellany/sheller'

Shellany::Sheller.stdout("echo abc") # => "abc"
Shellany::Sheller.stderr("touch /foo") # => "touch: cannot touch  ‘/aef’: Permission denied
Shellany::Sheller.run("false") # => false
Shellany::Sheller.system("clear") # => clears screen (no capture done)
```

Using Sheller object:

```ruby
require 'shellany/sheller'

sh = Shellany::Sheller.new('grep /etc/passed|tail -n 1') # does nothing

sh.stdout # shows output (runs the command since it wasn't run)
sh.stderr # shows stderr (does not run the command)
sh.ok? # returns true if exit code was zero (does not run the command)
```

## Project status

Only developed enough for Guard to run, though pull requests are more than welcome.

Especially for:

- better API
- better shell detection code
- better support for various system() arguments
- better support for redireciton handling
- better support for shell detection (e.g. Windows)

## Contributing

1. Fork it ( https://github.com/[my-github-username]/shellany/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
