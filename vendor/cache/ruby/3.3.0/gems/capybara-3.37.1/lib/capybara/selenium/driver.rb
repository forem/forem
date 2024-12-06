# frozen_string_literal: true

require 'uri'
require 'English'

class Capybara::Selenium::Driver < Capybara::Driver::Base
  include Capybara::Selenium::Find

  DEFAULT_OPTIONS = {
    browser: :firefox,
    clear_local_storage: nil,
    clear_session_storage: nil
  }.freeze
  SPECIAL_OPTIONS = %i[browser clear_local_storage clear_session_storage timeout native_displayed].freeze
  CAPS_VERSION = Gem::Requirement.new('>= 4.0.0.alpha6')

  attr_reader :app, :options

  class << self
    attr_reader :selenium_webdriver_version

    def load_selenium
      require 'selenium-webdriver'
      require 'capybara/selenium/logger_suppressor'
      require 'capybara/selenium/patches/atoms'
      require 'capybara/selenium/patches/is_displayed'
      require 'capybara/selenium/patches/action_pauser'

      # Look up the version of `selenium-webdriver` to
      # see if it's a version we support.
      #
      # By default, we use Gem.loaded_specs to determine
      # the version number. However, in some cases, such
      # as when loading `selenium-webdriver` outside of
      # Rubygems, we fall back to referencing
      # Selenium::WebDriver::VERSION. Ideally we'd
      # use the constant in all cases, but earlier versions
      # of `selenium-webdriver` didn't provide the constant.
      @selenium_webdriver_version =
        if Gem.loaded_specs['selenium-webdriver']
          Gem.loaded_specs['selenium-webdriver'].version
        else
          Gem::Version.new(Selenium::WebDriver::VERSION)
        end

      unless Gem::Requirement.new('>= 3.142.7').satisfied_by? @selenium_webdriver_version
        warn "Warning: You're using an unsupported version of selenium-webdriver, please upgrade."
      end

      @selenium_webdriver_version
    rescue LoadError => e
      raise e unless e.message.include?('selenium-webdriver')

      raise LoadError, "Capybara's selenium driver is unable to load `selenium-webdriver`, please install the gem and add `gem 'selenium-webdriver'` to your Gemfile if you are using bundler."
    end

    attr_reader :specializations

    def register_specialization(browser_name, specialization)
      @specializations ||= {}
      @specializations[browser_name] = specialization
    end
  end

  def browser
    unless @browser
      options[:http_client] ||= begin
        require 'capybara/selenium/patches/persistent_client'
        if options[:timeout]
          ::Capybara::Selenium::PersistentClient.new(read_timeout: options[:timeout])
        else
          ::Capybara::Selenium::PersistentClient.new
        end
      end
      processed_options = options.reject { |key, _val| SPECIAL_OPTIONS.include?(key) }

      @browser = if options[:browser] == :firefox &&
                    RUBY_VERSION >= '3.0' &&
                    Capybara::Selenium::Driver.selenium_webdriver_version <= Gem::Version.new('4.0.0.alpha1')
        # selenium-webdriver 3.x doesn't correctly pass options through for Firefox with Ruby 3 so workaround that
        Selenium::WebDriver::Firefox::Driver.new(**processed_options)
      else
        Selenium::WebDriver.for(options[:browser], processed_options)
      end

      specialize_driver
      setup_exit_handler
    end
    @browser
  end

  def initialize(app, **options)
    super()
    self.class.load_selenium
    @app = app
    @browser = nil
    @exit_status = nil
    @frame_handles = Hash.new { |hash, handle| hash[handle] = [] }
    @options = DEFAULT_OPTIONS.merge(options)
    @node_class = ::Capybara::Selenium::Node
  end

  def visit(path)
    browser.navigate.to(path)
  end

  def refresh
    browser.navigate.refresh
  end

  def go_back
    browser.navigate.back
  end

  def go_forward
    browser.navigate.forward
  end

  def html
    browser.page_source
  rescue Selenium::WebDriver::Error::JavascriptError => e
    raise unless e.message.include?('documentElement is null')
  end

  def title
    browser.title
  end

  def current_url
    browser.current_url
  end

  def wait?; true; end
  def needs_server?; true; end

  def execute_script(script, *args)
    browser.execute_script(script, *native_args(args))
  end

  def evaluate_script(script, *args)
    result = execute_script("return #{script}", *args)
    unwrap_script_result(result)
  end

  def evaluate_async_script(script, *args)
    browser.manage.timeouts.script_timeout = Capybara.default_max_wait_time
    result = browser.execute_async_script(script, *native_args(args))
    unwrap_script_result(result)
  end

  def active_element
    build_node(native_active_element)
  end

  def send_keys(*args)
    # Should this call the specialized nodes rather than native???
    native_active_element.send_keys(*args)
  end

  def save_screenshot(path, **_options)
    browser.save_screenshot(path)
  end

  def reset!
    # Use instance variable directly so we avoid starting the browser just to reset the session
    return unless @browser

    navigated = false
    timer = Capybara::Helpers.timer(expire_in: 10)
    begin
      # Only trigger a navigation if we haven't done it already, otherwise it
      # can trigger an endless series of unload modals
      reset_browser_state unless navigated
      navigated = true
      # Ensure the page is empty and trigger an UnhandledAlertError for any modals that appear during unload
      wait_for_empty_page(timer)
    rescue *unhandled_alert_errors
      # This error is thrown if an unhandled alert is on the page
      # Firefox appears to automatically dismiss this alert, chrome does not
      # We'll try to accept it
      accept_unhandled_reset_alert
      # try cleaning up the browser again
      retry
    end
  end

  def frame_obscured_at?(x:, y:)
    frame = @frame_handles[current_window_handle].last
    return false unless frame

    switch_to_frame(:parent)
    begin
      frame.base.obscured?(x: x, y: y)
    ensure
      switch_to_frame(frame)
    end
  end

  def switch_to_frame(frame)
    handles = @frame_handles[current_window_handle]
    case frame
    when :top
      handles.clear
      browser.switch_to.default_content
    when :parent
      handles.pop
      browser.switch_to.parent_frame
    else
      handles << frame
      browser.switch_to.frame(frame.native)
    end
  end

  def current_window_handle
    browser.window_handle
  end

  def window_size(handle)
    within_given_window(handle) do
      size = browser.manage.window.size
      [size.width, size.height]
    end
  end

  def resize_window_to(handle, width, height)
    within_given_window(handle) do
      browser.manage.window.resize_to(width, height)
    end
  end

  def maximize_window(handle)
    within_given_window(handle) do
      browser.manage.window.maximize
    end
    sleep 0.1 # work around for https://code.google.com/p/selenium/issues/detail?id=7405
  end

  def fullscreen_window(handle)
    within_given_window(handle) do
      browser.manage.window.full_screen
    end
  end

  def close_window(handle)
    raise ArgumentError, 'Not allowed to close the primary window' if handle == window_handles.first

    within_given_window(handle) do
      browser.close
    end
  end

  def window_handles
    browser.window_handles
  end

  def open_new_window(kind = :tab)
    if browser.switch_to.respond_to?(:new_window)
      handle = current_window_handle
      browser.switch_to.new_window(kind)
      switch_to_window(handle)
    else
      browser.manage.new_window(kind)
    end
  rescue NoMethodError, Selenium::WebDriver::Error::WebDriverError
    # If not supported by the driver or browser default to using JS
    browser.execute_script('window.open();')
  end

  def switch_to_window(handle)
    browser.switch_to.window handle
  end

  def accept_modal(_type, **options)
    yield if block_given?
    modal = find_modal(**options)

    modal.send_keys options[:with] if options[:with]

    message = modal.text
    modal.accept
    message
  end

  def dismiss_modal(_type, **options)
    yield if block_given?
    modal = find_modal(**options)
    message = modal.text
    modal.dismiss
    message
  end

  def quit
    @browser&.quit
  rescue Selenium::WebDriver::Error::SessionNotCreatedError, Errno::ECONNREFUSED,
         Selenium::WebDriver::Error::InvalidSessionIdError
    # Browser must have already gone
  rescue Selenium::WebDriver::Error::UnknownError => e
    unless silenced_unknown_error_message?(e.message) # Most likely already gone
      # probably already gone but not sure - so warn
      warn "Ignoring Selenium UnknownError during driver quit: #{e.message}"
    end
  ensure
    @browser = nil
  end

  def invalid_element_errors
    @invalid_element_errors ||=
      [
        ::Selenium::WebDriver::Error::StaleElementReferenceError,
        ::Selenium::WebDriver::Error::ElementNotInteractableError,
        ::Selenium::WebDriver::Error::InvalidSelectorError, # Work around chromedriver go_back/go_forward race condition
        ::Selenium::WebDriver::Error::ElementClickInterceptedError,
        ::Selenium::WebDriver::Error::NoSuchElementError, # IE
        ::Selenium::WebDriver::Error::InvalidArgumentError # IE
      ].tap do |errors|
        unless selenium_4?
          ::Selenium::WebDriver.logger.suppress_deprecations do
            errors.concat [
              ::Selenium::WebDriver::Error::UnhandledError,
              ::Selenium::WebDriver::Error::ElementNotVisibleError,
              ::Selenium::WebDriver::Error::InvalidElementStateError,
              ::Selenium::WebDriver::Error::ElementNotSelectableError
            ]
          end
        end
      end
  end

  def no_such_window_error
    Selenium::WebDriver::Error::NoSuchWindowError
  end

private

  def selenium_4?
    defined?(Selenium::WebDriver::VERSION) && (Selenium::WebDriver::VERSION.to_f >= 4)
  end

  def native_args(args)
    args.map { |arg| arg.is_a?(Capybara::Selenium::Node) ? arg.native : arg }
  end

  def native_active_element
    browser.switch_to.active_element
  end

  def clear_browser_state
    delete_all_cookies
    clear_storage
  rescue *clear_browser_state_errors
    # delete_all_cookies fails when we've previously gone
    # to about:blank, so we rescue this error and do nothing
    # instead.
  end

  def clear_browser_state_errors
    @clear_browser_state_errors ||= [Selenium::WebDriver::Error::UnknownError]
  end

  def unhandled_alert_errors
    @unhandled_alert_errors ||= with_legacy_error(
      [Selenium::WebDriver::Error::UnexpectedAlertOpenError],
      'UnhandledAlertError'
    )
  end

  def delete_all_cookies
    @browser.manage.delete_all_cookies
  end

  def clear_storage
    clear_session_storage unless options[:clear_session_storage] == false
    clear_local_storage unless options[:clear_local_storage] == false
  rescue Selenium::WebDriver::Error::JavascriptError
    # session/local storage may not be available if on non-http pages (e.g. about:blank)
  end

  def clear_session_storage
    if @browser.respond_to? :session_storage
      @browser.session_storage.clear
    else
      begin
        @browser&.execute_script('window.sessionStorage.clear()')
      rescue # rubocop:disable Style/RescueStandardError
        unless options[:clear_session_storage].nil?
          warn 'sessionStorage clear requested but is not supported by this driver'
        end
      end
    end
  end

  def clear_local_storage
    if @browser.respond_to? :local_storage
      @browser.local_storage.clear
    else
      begin
        @browser&.execute_script('window.localStorage.clear()')
      rescue # rubocop:disable Style/RescueStandardError
        unless options[:clear_local_storage].nil?
          warn 'localStorage clear requested but is not supported by this driver'
        end
      end
    end
  end

  def navigate_with_accept(url)
    @browser.navigate.to(url)
    sleep 0.1 # slight wait for alert
    @browser.switch_to.alert.accept
  rescue modal_error
    # alert now gone, should mean navigation happened
  end

  def modal_error
    Selenium::WebDriver::Error::NoSuchAlertError
  end

  def within_given_window(handle)
    original_handle = current_window_handle
    if handle == original_handle
      yield
    else
      switch_to_window(handle)
      result = yield
      switch_to_window(original_handle)
      result
    end
  end

  def find_modal(text: nil, **options)
    # Selenium has its own built in wait (2 seconds)for a modal to show up, so this wait is really the minimum time
    # Actual wait time may be longer than specified
    wait = Selenium::WebDriver::Wait.new(
      timeout: options.fetch(:wait, session_options.default_max_wait_time) || 0,
      ignore: modal_error
    )
    begin
      wait.until do
        alert = @browser.switch_to.alert
        regexp = text.is_a?(Regexp) ? text : Regexp.new(Regexp.escape(text.to_s))
        matched = alert.text.match?(regexp)
        unless matched
          raise Capybara::ModalNotFound, "Unable to find modal dialog with #{text} - found '#{alert.text}' instead."
        end

        alert
      end
    rescue *find_modal_errors
      raise Capybara::ModalNotFound, "Unable to find modal dialog#{" with #{text}" if text}"
    end
  end

  def find_modal_errors
    @find_modal_errors ||= with_legacy_error([Selenium::WebDriver::Error::TimeoutError], 'TimeOutError')
  end

  def with_legacy_error(errors, legacy_error)
    errors.tap do |errs|
      unless selenium_4?
        ::Selenium::WebDriver.logger.suppress_deprecations do
          errs << Selenium::WebDriver::Error.const_get(legacy_error)
        end
      end
    end
  end

  def silenced_unknown_error_message?(msg)
    silenced_unknown_error_messages.any? { |regex| msg.match? regex }
  end

  def silenced_unknown_error_messages
    [/Error communicating with the remote browser/]
  end

  def unwrap_script_result(arg)
    # TODO: move into the case when we drop support for Selenium < 4.1
    element_types = [Selenium::WebDriver::Element]
    element_types.push(Selenium::WebDriver::ShadowRoot) if defined?(Selenium::WebDriver::ShadowRoot)

    case arg
    when Array
      arg.map { |arr| unwrap_script_result(arr) }
    when Hash
      arg.transform_values! { |value| unwrap_script_result(value) }
    when *element_types
      build_node(arg)
    else
      arg
    end
  end

  def find_context
    browser
  end

  def build_node(native_node, initial_cache = {})
    ::Capybara::Selenium::Node.new(self, native_node, initial_cache)
  end

  def bridge
    browser.send(:bridge)
  end

  def specialize_driver
    browser_type = browser.browser
    Capybara::Selenium::Driver.specializations.select { |k, _v| k === browser_type }.each_value do |specialization| # rubocop:disable Style/CaseEquality
      extend specialization
    end
  end

  def setup_exit_handler
    main = Process.pid
    at_exit do
      # Store the exit status of the test run since it goes away after calling the at_exit proc...
      @exit_status = $ERROR_INFO.status if $ERROR_INFO.is_a?(SystemExit)
      quit if Process.pid == main
      exit @exit_status if @exit_status # Force exit with stored status
    end
  end

  def reset_browser_state
    clear_browser_state
    @browser.navigate.to('about:blank')
  end

  def wait_for_empty_page(timer)
    until find_xpath('/html/body/*').empty?
      raise Capybara::ExpectationNotMet, 'Timed out waiting for Selenium session reset' if timer.expired?

      sleep 0.01

      # It has been observed that it is possible that asynchronous JS code in
      # the application under test can navigate the browser away from about:blank
      # if the timing is just right. Ensure we are still at about:blank...
      @browser.navigate.to('about:blank') unless current_url == 'about:blank'
    end
  end

  def accept_unhandled_reset_alert
    @browser.switch_to.alert.accept
    sleep 0.25 # allow time for the modal to be handled
  rescue modal_error
    # The alert is now gone.
    # If navigation has not occurred attempt again and accept alert
    # since FF may have dismissed the alert at first attempt.
    navigate_with_accept('about:blank') if current_url != 'about:blank'
  end
end

require 'capybara/selenium/driver_specializations/chrome_driver'
require 'capybara/selenium/driver_specializations/firefox_driver'
require 'capybara/selenium/driver_specializations/internet_explorer_driver'
require 'capybara/selenium/driver_specializations/safari_driver'
require 'capybara/selenium/driver_specializations/edge_driver'
