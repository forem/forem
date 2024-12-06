# frozen_string_literal: true

require 'capybara/dsl'

Capybara.app = Rack::Builder.new do
  map '/' do
    run Rails.application
  end
end.to_app

Capybara.save_path = Rails.root.join('tmp/capybara')

# Override default rack_test driver to respect data-method attributes.
Capybara.register_driver :rack_test do |app|
  Capybara::RackTest::Driver.new(app, respect_data_method: true)
end
