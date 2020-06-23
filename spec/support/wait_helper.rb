module WaitHelper
  def wait_for_assertion
    timeout = 10
    start = Time.current
    success = false
    success = yield until success || (Time.current - start) > timeout
    raise "WaitHelper.wait_for_assertion assertion not met in #{timeout}s" unless success
  end
end
