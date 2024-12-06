# frozen_string_literal: true

require 'rubygems'
require 'pry'
require 'rspec'
require 'active_model'

I18n.enforce_available_locales = false

require 'simplecov'
SimpleCov.start 'rails'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'email_validator'

class TestModel
  include ActiveModel::Validations

  def initialize(attributes = {})
    @attributes = attributes
  end

  def read_attribute_for_validation(key)
    @attributes[key]
  end
end

RSpec.configure(&:disable_monkey_patching!)
