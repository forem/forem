source "http://rubygems.org"

gem 'json', '>= 1.5.1'
gem 'algolia', '< 3.0.0'

if defined?(RUBY_ENGINE) && RUBY_ENGINE == 'rbx'
  gem 'rubysl', '~> 2.0', :platform => :rbx
end

group :test do
  rails_version = ENV["RAILS_VERSION"] || '6.1'
  gem 'rails', "~> #{rails_version}"
  gem 'active_model_serializers'
  if Gem::Version.new(rails_version) >= Gem::Version.new('6.0')
    gem 'sqlite3', '~> 1.4.0', :platform => [:rbx, :ruby]
  else
    gem 'sqlite3', '< 1.4.0', :platform => [:rbx, :ruby]
  end
  gem 'rspec', '>= 2.5.0', '< 3.0'
  gem 'jdbc-sqlite3', :platform => :jruby
  gem 'activerecord-jdbc-adapter', :platform => :jruby
  gem 'activerecord-jdbcsqlite3-adapter', :platform => :jruby
  gem 'redgreen'

  sequel_version = ENV['SEQUEL_VERSION'] ? "~> #{ENV['SEQUEL_VERSION']}" : '>= 4.0'
  gem 'sequel', sequel_version
end

group :development do
  gem 'rake', '~> 10.1.0'
  gem 'rdoc'
end

group :test, :development do
  gem 'will_paginate', '>= 2.3.15'
  gem 'kaminari', '< 1'
  gem 'pagy'
end

