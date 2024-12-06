require 'rubygems'
require "bundler/setup"

require 'pry'

require 'rolify'
require 'rolify/matchers'
require 'rails/all'
require_relative 'support/stream_helpers'
include StreamHelpers

require 'coveralls'
Coveralls.wear_merged!

require 'common_helper'

ENV['ADAPTER'] ||= 'active_record'

if ENV['ADAPTER'] == 'active_record'
  load File.dirname(__FILE__) + '/support/adapters/utils/active_record.rb'
  require 'active_record/railtie'
  establish_connection
else
  load File.dirname(__FILE__) + '/support/adapters/utils/mongoid.rb'
  load_mongoid_config
end

module TestApp
  class Application < ::Rails::Application
    config.root = File.dirname(__FILE__)
  end
end

require 'ammeter/init'
