source 'https://rubygems.org'

# Specify your gem's dependencies in request_store.gemspec
gemspec

case Gem::Version.new(RUBY_VERSION.dup)
when ->(ruby_version) { ruby_version >= Gem::Version.new('2.2.0') }
  gem 'rake', '~> 13'
when ->(ruby_version) { ruby_version >= Gem::Version.new('2.0.0') }
  gem 'rake', '~> 12.3.3'
else
  gem 'rake', '~> 11'
end
