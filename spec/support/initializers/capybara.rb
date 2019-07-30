require "capybara/rails"
require "capybara/rspec"
require "webdrivers/chromedriver"

Webdrivers::Chromedriver.required_version = "76.0.3809.68"
Webdrivers.cache_time = 86_400

Capybara.default_max_wait_time = 5

Capybara.register_driver :headless_chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new(
    args: %w[no-sandbox headless disable-gpu window-size=1920,1080 --enable-features=NetworkService,NetworkServiceInProcess],
    log_level: :error,
  )

  Capybara::Selenium::Driver.new app, browser: :chrome, options: options
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
