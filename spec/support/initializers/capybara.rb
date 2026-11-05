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
end

# adapted from <https://medium.com/doctolib-engineering/hunting-flaky-tests-2-waiting-for-ajax-bd76d79d9ee9>
def wait_for_javascript
  max_time = Capybara::Helpers.monotonic_time + Capybara.default_max_wait_time
  finished = false

  while Capybara::Helpers.monotonic_time < max_time
    finished = page.evaluate_script(<<~JS)
      typeof initializeBaseApp !== "undefined" &&
        typeof window.Forem !== "undefined" &&
        typeof window.Forem.initializeEnhancedCommentTextArea === "function" &&
        Boolean(document.body && document.body.getAttribute("data-page-initialized") === "true") &&
        (!document.getElementById("comments-container") ||
          document.getElementById("comments-container").dataset.commentsInitialized === "true")
    JS

    break if finished

    sleep 0.05
  end

  raise "wait_for_javascript timeout" unless finished
end
