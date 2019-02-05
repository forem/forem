require "capybara/rspec"
require "selenium/webdriver"

Capybara.server = :puma, { Silent: true }
Capybara.default_max_wait_time = 5
# Capybara::Screenshot.autosave_on_failure = ENV["CI"] ? false : true

RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :rack_test
  end

  config.before(:each, type: :system, js: true) do
    # driven_by :selenium_chrome_headless
    driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400]
  end
end
