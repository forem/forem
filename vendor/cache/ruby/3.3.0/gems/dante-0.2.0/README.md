# Dante

Turn any ruby into a daemon.

## Description

Dante is the simplest possible thing that will work to turn arbitrary ruby code into an executable that
can be started via command line or start/stop a daemon, and will store a pid file for you.

If you need to create a ruby executable and you want standard daemon start/stop with pid files
and no hassle, this gem will be a great way to get started.

## Installation

Add to your Gemfile:

```ruby
# Gemfile

gem "dante"
```

or to your gemspec:

```ruby
# mygem.gemspec

Gem::Specification.new do |s|
  s.add_dependency "dante"
end
```

## Usage

Dante is meant to be used from any "bin" executable. For instance, to create a binary for a web server, create a file in `bin/myapp`:

```ruby
#!/usr/bin/env ruby

require File.expand_path("../../myapp.rb", __FILE__)

Dante.run('myapp') do |opts|
  # opts: host, pid_path, port, daemonize, user, group
  Thin::Server.start('0.0.0.0', opts[:port]) do
    use Rack::CommonLogger
    use Rack::ShowExceptions
    run MyApp
  end
end
```

Be sure to properly make your bin executable:

```
chmod +x bin/myapp
```

### CLI

This gives your binary several useful things for free:

```
./bin/myapp
```

will start the app undaemonized in the terminal, handling trapping and stopping the process.

```
./bin/myapp -l /var/log/myapp.log
```

will start the app undaemonized in the terminal and redirect all stdout and stderr to the specified logfile.

```
./bin/myapp -p 8080 -d -P /var/run/myapp.pid -l /var/log/myapp.log
```

will daemonize and start the process, storing the pid in the specified pid file.
All stdout and stderr will be redirected to the specified logfile. If no logfile is specified in daemon mode then all 
stdout and stderr will be directed to /var/log/<myapp name>.log.

```
./bin/myapp -k -P /var/run/myapp.pid
```

will stop all daemonized processes for the specified pid file.

```
./bin/myapp --help
```

Will return a useful help banner message explaining the simple usage.

### Advanced

In many cases, you will need to add custom flags/options or a custom description to your executable. You can do this
easily by using `Dante::Runner` more explicitly:

```ruby
#!/usr/bin/env ruby

require File.expand_path("../../myapp.rb", __FILE__)

# Set default port to 8080
runner = Dante::Runner.new('myapp', :port => 8080)
# Sets the description in 'help'
runner.description = "This is myapp"
# Setup custom 'test' option flag
runner.with_options do |opts|
  opts.on("-t", "--test TEST", String, "Test this thing") do |test|
    options[:test] = test
  end
end
# Create validation hook for options
runner.verify_options_hook = lambda { |opts|
  raise Exception.new("Must supply test parameter") if opts[:test].nil?
}
# Parse command-line options and execute the process
runner.execute do |opts|
  # opts: host, pid_path, port, daemonize, user, group
  Thin::Server.start('0.0.0.0', opts[:port]) do
    puts opts[:test] # Referencing my custom option
    use Rack::CommonLogger
    use Rack::ShowExceptions
    run MyApp
  end
end
```

Now you would be able to do:

```
./bin/myapp -t custom
```

and the `opts` would contain the `:test` option for use in your script. In addition, help will now contain
your customized description in the banner.

You can also use dante programmatically to start, stop and restart arbitrary code:

```ruby
# daemon start
Dante::Runner.new('gitdocs').execute(:daemonize => true, :pid_path => @pid, :log_path => @log_path) { something! }
# daemon stop
Dante::Runner.new('gitdocs').execute(:kill => true, :pid_path => @pid)
# daemon restart
Dante::Runner.new('gitdocs').execute(:daemonize => true, :restart => true, :pid_path => @pid) { something! }
```

so you can use dante as part of a more complex CLI executable.

## God

Dante can be used well in conjunction with the excellent God process manager. Simply, use Dante to daemonize a process
and then you can easily use God to monitor:

```ruby
# /etc/god/myapp.rb

God.watch do |w|
  w.name            = "myapp"
  w.interval        = 30.seconds
  w.start           = "ruby /path/to/myapp/bin/myapp -d"
  w.stop            = "ruby /path/to/myapp/bin/myapp -k"
  w.start_grace     = 15.seconds
  w.restart_grace   = 15.seconds
  w.pid_file        = "/var/run/myapp.pid"

  w.behavior(:clean_pid_file)

  w.start_if do |start|
    start.condition(:process_running) do |c|
      c.interval = 5.seconds
      c.running = false
    end
  end
end
```

and that's all. Of course now you can also easily daemonize as well as start/stop the process on the command line as well.

## Copyright

Copyright © 2011 Nathan Esquenazi. See [LICENSE](https://github.com/bazaarlabs/dante/blob/master/LICENSE) for details.
