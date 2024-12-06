require 'honeybadger/ruby'

Honeybadger.init!({
  :framework      => :ruby,
  :env            => ENV['RUBY_ENV'] || ENV['RACK_ENV'],
  :'logging.path' => 'STDOUT'
})

Honeybadger.load_plugins!

Honeybadger.install_at_exit_callback
