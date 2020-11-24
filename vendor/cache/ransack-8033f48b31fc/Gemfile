source 'https://rubygems.org'
gemspec

gem 'rake'

rails = ENV['RAILS'] || '6-0-stable'

rails_version = case rails
                when /\// # A path
                  File.read(File.join(rails, "RAILS_VERSION"))
                when /^v/ # A tagged version
                  rails.gsub(/^v/, '')
                else
                  rails
                end

gem 'faker', '~> 1.0'
gem 'sqlite3', ::Gem::Version.new(rails_version) >= ::Gem::Version.new('6-0-stable') ? '~> 1.4.1' : '~> 1.3.3'
gem 'pg', '~> 1.0'
gem 'pry', '~> 0.12.2'
gem 'byebug'

case rails
when /\// # A path
  gem 'activesupport', path: "#{rails}/activesupport"
  gem 'activemodel', path: "#{rails}/activemodel"
  gem 'activerecord', path: "#{rails}/activerecord", require: false
  gem 'actionpack', path: "#{rails}/actionpack"
  gem 'actionview', path: "#{rails}/actionview"
when /^v/ # A tagged version
  git 'https://github.com/rails/rails.git', :tag => rails do
    gem 'activesupport'
    gem 'activemodel'
    gem 'activerecord', require: false
    gem 'actionpack'
  end
else
  git 'https://github.com/rails/rails.git', :branch => rails do
    gem 'activesupport'
    gem 'activemodel'
    gem 'activerecord', require: false
    gem 'actionpack'
  end
end
gem 'mysql2', '~> 0.5.2'

group :test do
  gem 'machinist', '~> 1.0.6'
  gem 'rspec', '~> 3'
  gem 'simplecov', :require => false
end
