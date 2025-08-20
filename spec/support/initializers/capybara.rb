require "capybara/rails"
require "capybara/rspec"

Capybara.server_host = "0.0.0.0"
Capybara.app_host = "http://#{ENV.fetch('APP_HOST', `hostname`.strip&.downcase || '0.0.0.0')}"
Capybara.default_max_wait_time = 10
Capybara.save_path = ENV.fetch("CAPYBARA_ARTIFACTS", "./tmp/capybara")

RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :rack_test
  end

  config.before(:each, :js, type: :system) do
    driven_by :better_cuprite
  end

  # Take screenshots on system test failures for debugging
  config.after(:each, type: :system) do |example|
    if example.exception.present? && !example.metadata[:skip_screenshot]
      screenshot_path = Rails.root.join("tmp/capybara/screenshot_#{Time.current.to_i}.png")
      page.save_screenshot(screenshot_path)
      puts "Screenshot saved to: #{screenshot_path}"
    end
  end
end

# adapted from <https://medium.com/doctolib-engineering/hunting-flaky-tests-2-waiting-for-ajax-bd76d79d9ee9>
def wait_for_javascript
  max_time = Capybara::Helpers.monotonic_time + Capybara.default_max_wait_time
  finished = false

  while Capybara::Helpers.monotonic_time < max_time
    begin
      # Check if the base app is initialized and DOM is ready
      finished = page.evaluate_script("typeof initializeBaseApp") != "undefined" &&
                 page.evaluate_script("document.readyState") == "complete" &&
                 page.evaluate_script("typeof $ !== 'undefined' ? $.active === 0 : true") # Check for jQuery AJAX completion if present
    rescue Selenium::WebDriver::Error::JavaScriptError, Capybara::NotSupportedByDriverError
      # Handle cases where JavaScript evaluation fails
      finished = false
    end

    break if finished

    sleep 0.1
  end

  raise "wait_for_javascript timeout: initializeBaseApp not found or DOM not ready" unless finished
end

# Additional helper for waiting for specific elements to appear with better error messages
def wait_for_element(selector, timeout: Capybara.default_max_wait_time)
  page.find(selector, wait: timeout)
rescue Capybara::ElementNotFound => e
  raise "Element '#{selector}' not found within #{timeout} seconds: #{e.message}"
end

# Helper for waiting for AJAX requests to complete
def wait_for_ajax
  Timeout.timeout(Capybara.default_max_wait_time) do
    loop until page.evaluate_script("typeof $ !== 'undefined' ? $.active === 0 : true")
  end
rescue Timeout::Error
  raise "AJAX requests did not complete within #{Capybara.default_max_wait_time} seconds"
end
