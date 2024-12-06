if defined?(Capistrano::Configuration.instance)
  require 'honeybadger/capistrano/legacy'
else
  load File.expand_path('../tasks/deploy.cap', __FILE__)
end
