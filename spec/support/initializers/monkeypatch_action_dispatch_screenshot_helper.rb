# https://github.com/mattheworiordan/capybara-screenshot/issues/225
# https://stackoverflow.com/questions/44336581/turn-off-screenshots-in-rails-system-tests
# https://github.com/rails/rails/blob/master/actionpack/lib/action_dispatch/system_testing/test_helpers/screenshot_helper.rb#L64
# Without this monkeypatch, if there's multiple screenshots taken due to rspec/retry, each new screenshot
# will overwrite the last one.  This monkeypatch makes the screenshot name unique so they won't overwrite each other
require "action_dispatch/system_testing/test_helpers/screenshot_helper"
::ActionDispatch::SystemTesting::TestHelpers::ScreenshotHelper.module_eval do
  private

  def image_name
    "#{method_name}_#{Time.current.utc.strftime('%Y-%m-%dT%H:-%M-%S-%3NZ')}"
  end
end
