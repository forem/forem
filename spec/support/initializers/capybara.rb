require "capybara/rails"
require "capybara/rspec"
require "webdrivers/chromedriver"

Webdrivers::Chromedriver.required_version = "73.0.3683.68"
Webdrivers.cache_time = 86_400

Capybara.default_max_wait_time = 5

Capybara.register_driver :headless_chrome do |app|
  capabilities = Selenium::WebDriver::Remote::Capabilities.chrome(
    chromeOptions: { args: %w[headless disable-gpu no-sandbox window-size=1400,2000] },
  )
  Capybara::Selenium::Driver.new(app, browser: :chrome, desired_capabilities: capabilities)
end

Capybara.register_driver :chrome do |app|
  capabilities = Selenium::WebDriver::Remote::Capabilities.chrome(
    chromeOptions: { args: %w[no-sandbox window-size=1400,2000] },
  )
  Capybara::Selenium::Driver.new(app, browser: :chrome, desired_capabilities: capabilities)
end

RSpec.configure do |config|
  config.before(:all, type: :system) do
    Capybara.server = :puma, { Silent: true }
  end

  config.before(:each, type: :system) do
    driven_by :rack_test
  end

  config.before(:each, type: :system, js: true) do
    driven_by :headless_chrome
  end
end
