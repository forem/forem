require "capybara/rspec"
require "selenium/webdriver"

Capybara.server = :puma, { Silent: true }
Capybara.default_max_wait_time = 5

Capybara.register_driver :chrome do |app|
  Capybara::Selenium::Driver.new(app, browser: :chrome)
end

Capybara.register_driver :headless_chrome do |app|
  Capybara::Selenium::Driver.new app,
    browser: :chrome,
    desired_capabilities: Selenium::WebDriver::Remote::Capabilities.chrome(
      chromeOptions: { args: %w(headless disable-gpu no-sandbox window-size=1400,2000) },
    )
end

Capybara.javascript_driver = :headless_chrome
