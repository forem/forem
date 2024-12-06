# frozen_string_literal: true

# Define a bare test case to use with Capybara
class ActiveSupport::IntegrationCase < ActiveSupport::TestCase
  # include Capybara::DSL
  include Rails.application.routes.url_helpers
end