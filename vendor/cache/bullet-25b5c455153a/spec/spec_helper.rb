# frozen_string_literal: true

require 'rspec'
begin
  require 'active_record'
rescue LoadError

end
begin
  require 'mongoid'
rescue LoadError

end

module Rails
  class << self
    def root
      File.expand_path(__FILE__).split('/')[0..-3].join('/')
    end

    def env
      'test'
    end
  end
end

$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__) + '/../lib'))
require 'bullet'
extend Bullet::Dependency
Bullet.enable = true

MODELS = File.join(File.dirname(__FILE__), 'models')
$LOAD_PATH.unshift(MODELS)
SUPPORT = File.join(File.dirname(__FILE__), 'support')
Dir[File.join(SUPPORT, '*.rb')].reject { |filename| filename =~ /_seed.rb$/ }.sort.each { |file| require file }

RSpec.configure do |config|
  config.extend Bullet::Dependency

  config.filter_run focus: true
  config.run_all_when_everything_filtered = true
end

if active_record?
  ActiveRecord::Migration.verbose = false

  # Autoload every active_record model for the test suite that sits in spec/models.
  Dir[File.join(MODELS, '*.rb')].sort.each do |filename|
    name = File.basename(filename, '.rb')
    autoload name.camelize.to_sym, name
  end
  require File.join(SUPPORT, 'sqlite_seed.rb')

  RSpec.configure do |config|
    config.before(:suite) do
      Support::SqliteSeed.setup_db
      Support::SqliteSeed.seed_db
    end

    config.before(:example) do
      Bullet.start_request
      Bullet.enable = true
    end

    config.after(:example) { Bullet.end_request }
  end

  if ENV['BULLET_LOG']
    require 'logger'
    ActiveRecord::Base.logger = Logger.new(STDOUT)
  end
end

if mongoid?
  # Autoload every mongoid model for the test suite that sits in spec/models.
  Dir[File.join(MODELS, 'mongoid', '*.rb')].sort.each { |file| require file }
  require File.join(SUPPORT, 'mongo_seed.rb')

  RSpec.configure do |config|
    config.before(:suite) do
      Support::MongoSeed.setup_db
      Support::MongoSeed.seed_db
    end

    config.after(:suite) do
      Support::MongoSeed.setup_db
      Support::MongoSeed.teardown_db
    end

    config.before(:each) { Bullet.start_request }

    config.after(:each) { Bullet.end_request }
  end

  if ENV['BULLET_LOG']
    Mongoid.logger = Logger.new(STDOUT)
    Moped.logger = Logger.new(STDOUT)
  end
end
