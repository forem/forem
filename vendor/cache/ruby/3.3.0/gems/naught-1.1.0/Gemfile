source 'https://rubygems.org'

# Specify your gem's dependencies in naught.gemspec
gemspec

gem 'rake'

group :development do
  platforms :ruby_19, :ruby_20, :ruby_21, :ruby_22 do
    gem 'guard'
    gem 'guard-bundler'
    gem 'guard-rspec'
  end
  gem 'pry'
end

group :test do
  gem 'coveralls', :require => false
  gem 'json', :platforms => [:jruby, :rbx, :ruby_18, :ruby_19]
  gem 'libnotify'
  gem 'mime-types', '~> 1.25', :platforms => [:jruby, :ruby_18]
  gem 'rest-client', '~> 1.6.0', :platforms => [:jruby, :ruby_18]
  gem 'rspec', '>= 2.14'
  gem 'rubocop', '~> 0.34.0', :platforms => [:ruby_19, :ruby_20, :ruby_21, :ruby_22]
end
