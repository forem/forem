module WaitHelper
  # Pass in a block, and the block will get executed over and over again,
  # until it returns a truthy value
  def wait_for_assertion
    timeout = Capybara.default_max_wait_time
    start = Time.current
    success = false
    success = yield until success || (Time.current - start) > timeout
    raise "WaitHelper.wait_for_assertion assertion not met in #{timeout}s" unless success
  end

  def ensure_modal_opens
    wait_for_assertion do
      yield
      Capybara.current_session.driver.browser.switch_to.alert
      true
    rescue Selenium::WebDriver::Error::NoAlertPresentError, Capybara::ElementNotFound
      sleep 1 # sleep for JS to be active so click that activates modal happens
      false
    end
  end
end
