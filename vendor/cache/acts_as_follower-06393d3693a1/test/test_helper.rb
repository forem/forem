# Configure Rails Envinronment
ENV["RAILS_ENV"] = "test"

require File.expand_path("../dummy30/config/environment.rb",  __FILE__)
require "rails/test_help"

ActiveRecord::Base.logger = Logger.new(File.dirname(__FILE__) + '/debug.log')
ActiveRecord::Migration.verbose = false

load(File.dirname(__FILE__) + '/schema.rb')

require File.dirname(__FILE__) + '/../lib/generators/templates/model.rb'

require 'shoulda'
require 'shoulda_create'
require 'factory_girl'
ActiveSupport::TestCase.extend(ShouldaCreate)
FactoryGirl.find_definitions
