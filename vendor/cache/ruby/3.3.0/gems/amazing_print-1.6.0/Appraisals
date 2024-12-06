# frozen_string_literal: true

if RUBY_VERSION < '3'
  appraise 'rails-5.2' do
    gem 'activerecord-jdbcsqlite3-adapter', '~> 52.0', platform: :jruby
    gem 'rails', '~> 5.2.0'
    gem 'sqlite3', platform: :mri
  end

  appraise 'rails-6.0' do
    gem 'activerecord-jdbcsqlite3-adapter', '~> 60.0', platform: :jruby
    gem 'rails', '~> 6.0.0'
    gem 'sqlite3', platform: :mri
  end

  appraise 'mongoid-4.0' do
    # https://github.com/rails/rails/issues/34822#issuecomment-570670516
    gem 'bigdecimal', '~> 1.4', platforms: :mri
    gem 'mongoid', '~> 4.0.0'
  end

  appraise 'mongoid-5.0' do
    # https://github.com/rails/rails/issues/34822#issuecomment-570670516
    gem 'bigdecimal', '~> 1.4', platforms: :mri
    gem 'mongoid', '~> 5.0.0'
  end

  appraise 'mongoid-6.0' do
    gem 'mongoid', '~> 6.0.0'
  end

  appraise 'mongo_mapper' do
    gem 'activemodel', '~> 4.2.0'
    gem 'activesupport', '~> 4.2.0'
    gem 'bigdecimal', '~> 1.4', platforms: :mri
    gem 'mongo_mapper', '~> 0.14'
  end
end

if RUBY_VERSION >= '2.7'
  appraise 'rails-7.0' do
    gem 'activerecord-jdbcsqlite3-adapter', '~> 70.0', platform: :jruby
    gem 'rails', '~> 7.0.0'
    gem 'sqlite3', platform: :mri
  end

  appraise 'mongoid-7.0' do
    gem 'mongoid', '~> 7.0.0'
  end

  appraise 'mongoid-8.0' do
    gem 'mongoid', '~> 8.0.0'
  end
end

appraise 'rails-6.1' do
  gem 'activerecord-jdbcsqlite3-adapter', '~> 61.0', platform: :jruby
  gem 'rails', '~> 6.1.0'
  gem 'sqlite3', platform: :mri
end

appraise 'sequel-5.0' do
  gem 'jdbc-sqlite3', platform: :jruby
  gem 'sequel', '~> 5.0'
  gem 'sqlite3', platform: :mri
end
