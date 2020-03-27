require "capybara/rails"
require "capybara/rspec"
require "webdrivers/chromedriver"

Webdrivers.cache_time = 86_400

Capybara.default_max_wait_time = 10

Capybara.register_driver :headless_chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new(
    args: %w[no-sandbox headless disable-gpu window-size=1920,1080 --enable-features=NetworkService,NetworkServiceInProcess],
    log_level: :error,
  )

  Capybara::Selenium::Driver.new app, browser: :chrome, options: options
end

RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :rack_test
  end

  config.before(:each, type: :system, js: true) do
    driven_by :headless_chrome
  end
end

# adapted from <https://medium.com/doctolib-engineering/hunting-flaky-tests-2-waiting-for-ajax-bd76d79d9ee9>
def wait_for_javascript
  max_time = Capybara::Helpers.monotonic_time + Capybara.default_max_wait_time
  finished = false

  while Capybara::Helpers.monotonic_time < max_time
    finished = page.evaluate_script("typeof initializeBaseApp") != "undefined"

    break if finished

    sleep 0.1
  end

  raise "wait_for_javascript timeout" unless finished
end
