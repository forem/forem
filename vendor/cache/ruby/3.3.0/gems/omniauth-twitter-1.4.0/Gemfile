source 'https://rubygems.org'

gemspec

gem 'rake'

group :test do
  if Gem::Version.create(RUBY_VERSION) < Gem::Version.create("2.0.0")
    # for jruby 1.7.x
    gem "addressable", "2.4.0"
  end

  if Gem::Version.create(RUBY_VERSION) < Gem::Version.create("2.2.2")
    gem "rack", "~> 1.6"
  end

  gem 'rspec', '~> 3.2'
  gem 'rack-test'
  gem 'simplecov'
  gem 'webmock'
end
