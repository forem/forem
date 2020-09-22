source 'https://rubygems.org'

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

group :test do
  gem 'coveralls'
  gem 'simplecov', '>= 0.9'
end

ruby_version = Gem::Version.new(RUBY_VERSION)
debuggable_version = Gem::Version.new('2.6')

group :development, :test do
  if ruby_version >= debuggable_version
    gem 'pry'
    gem 'byebug'
    gem 'pry-byebug'
  end
end

# Specify non-special dependencies in oauth2.gemspec
gemspec
