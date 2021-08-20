require "capybara/rspec"
require "view_component/test_helpers"

RSpec.configure do |config|
  config.include Capybara::RSpecMatchers, type: :component
  config.include ViewComponent::TestHelpers, type: :component
  config.include Rails.application.routes.url_helpers, type: :component
end
