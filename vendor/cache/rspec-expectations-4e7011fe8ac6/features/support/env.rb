require 'aruba/cucumber'

Aruba.configure do |config|
  if RUBY_PLATFORM =~ /java/ || defined?(Rubinius)
    config.exit_timeout = 60
  else
    config.exit_timeout = 10
  end
end

Before do
  if RUBY_PLATFORM == 'java'
    # disable JIT since these processes are so short lived
    set_environment_variable('JRUBY_OPTS', "-X-C #{ENV['JRUBY_OPTS']}")
  end

  if defined?(Rubinius)
    # disable JIT since these processes are so short lived
    set_environment_variable('RBXOPT', "-Xint=true #{ENV['RBXOPT']}")
  end
end
