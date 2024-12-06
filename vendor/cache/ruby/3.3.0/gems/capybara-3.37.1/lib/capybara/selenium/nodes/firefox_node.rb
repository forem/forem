# frozen_string_literal: true

require 'capybara/selenium/extensions/html5_drag'
require 'capybara/selenium/extensions/file_input_click_emulation'

class Capybara::Selenium::FirefoxNode < Capybara::Selenium::Node
  include Html5Drag
  include FileInputClickEmulation

  def click(keys = [], **options)
    super
  rescue ::Selenium::WebDriver::Error::ElementNotInteractableError
    if tag_name == 'tr'
      warn 'You are attempting to click a table row which has issues in geckodriver/marionette - '\
           'see https://github.com/mozilla/geckodriver/issues/1228. Your test should probably be '\
           'clicking on a table cell like a user would. Clicking the first cell in the row instead.'
      return find_css('th:first-child,td:first-child')[0].click(keys, **options)
    end
    raise
  end

  def disabled?
    driver.evaluate_script("arguments[0].matches(':disabled, select:disabled *')", self)
  end

  def set_file(value) # rubocop:disable Naming/AccessorMethodName
    # By default files are appended so we have to clear here if its multiple and already set
    driver.execute_script(<<~JS, self)
      if (arguments[0].multiple && arguments[0].files.length){
        arguments[0].value = null;
      }
    JS
    return super if browser_version >= 62.0

    # Workaround lack of support for multiple upload by uploading one at a time
    path_names = value.to_s.empty? ? [] : Array(value)
    if (fd = bridge.file_detector) && !driver.browser.respond_to?(:upload)
      path_names.map! { |path| upload(fd.call([path])) || path }
    end
    path_names.each { |path| native.send_keys(path) }
  end

  def focused?
    driver.evaluate_script('arguments[0] == document.activeElement', self)
  end

  def send_keys(*args)
    # https://github.com/mozilla/geckodriver/issues/846
    return super(*args.map { |arg| arg == :space ? ' ' : arg }) if args.none?(Array)

    native.click unless focused?

    _send_keys(args).perform
  end

  def drop(*args)
    html5_drop(*args)
  end

  def hover
    return super unless browser_version >= 65.0

    # work around issue 2156 - https://github.com/teamcapybara/capybara/issues/2156
    scroll_if_needed { browser_action.move_to(native, 0, 0).move_to(native).perform }
  end

  def select_option
    # To optimize to only one check and then click
    selected_or_disabled = driver.evaluate_script(<<~JS, self)
      arguments[0].matches(':disabled, select:disabled *, :checked')
    JS
    click unless selected_or_disabled
  end

  def visible?
    return super unless native_displayed?

    begin
      bridge.send(:execute, :is_element_displayed, id: native_id)
    rescue Selenium::WebDriver::Error::UnknownCommandError
      # If the is_element_displayed command is unknown, no point in trying again
      driver.options[:native_displayed] = false
      super
    end
  end

private

  def native_displayed?
    (driver.options[:native_displayed] != false) && !ENV['DISABLE_CAPYBARA_SELENIUM_OPTIMIZATIONS']
  end

  def perform_with_options(click_options)
    # Firefox/marionette has an issue clicking with offset near viewport edge
    # scroll element to middle just in case
    scroll_to_center if click_options.coords?
    super
  end

  def _send_keys(keys, actions = browser_action, down_keys = ModifierKeysStack.new)
    case keys
    when :control, :left_control, :right_control,
         :alt, :left_alt, :right_alt,
         :shift, :left_shift, :right_shift,
         :meta, :left_meta, :right_meta,
         :command
      down_keys.press(keys)
      actions.key_down(keys)
    when String
      # https://bugzilla.mozilla.org/show_bug.cgi?id=1405370
      keys = keys.upcase if (browser_version < 64.0) && down_keys&.include?(:shift)
      actions.send_keys(keys)
    when Symbol
      actions.send_keys(keys)
    when Array
      down_keys.push
      keys.each { |sub_keys| _send_keys(sub_keys, actions, down_keys) }
      down_keys.pop.reverse_each { |key| actions.key_up(key) }
    else
      raise ArgumentError, 'Unknown keys type'
    end
    actions
  end

  def upload(local_file)
    return nil unless local_file
    raise ArgumentError, "You may only upload files: #{local_file.inspect}" unless File.file?(local_file)

    file = ::Selenium::WebDriver::Zipper.zip_file(local_file)
    bridge.http.call(:post, "session/#{bridge.session_id}/file", file: file)['value']
  end

  def browser_version
    driver.browser.capabilities[:browser_version].to_f
  end
end
