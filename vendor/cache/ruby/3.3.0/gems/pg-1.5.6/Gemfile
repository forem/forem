# -*- ruby -*-

# Specify your gem's runtime dependencies in pg.gemspec
gemspec

source "https://rubygems.org/"

group :development, :test do
  gem "bundler", ">= 1.16", "< 3.0"
  gem "rake-compiler", "~> 1.0"
  gem "rake-compiler-dock", "~> 1.0"
  gem "rdoc", "~> 6.4"
  gem "rspec", "~> 3.5"
  # "bigdecimal" is a gem on ruby-3.4+ and it's optional for ruby-pg.
  # Specs should succeed without it, but 4 examples are then excluded.
  # gem "bigdecimal", "~> 3.0"
end
