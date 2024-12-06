# frozen_string_literal: true

# require 'capybara/selenium/extensions/html5_drag'
require 'capybara/selenium/extensions/modifier_keys_stack'

class Capybara::Selenium::SafariNode < Capybara::Selenium::Node
  # include Html5Drag

  def click(keys = [], **options)
    # driver.execute_script('arguments[0].scrollIntoViewIfNeeded({block: "center"})', self)
    super
  rescue ::Selenium::WebDriver::Error::ElementNotInteractableError
    if tag_name == 'tr'
      warn 'You are attempting to click a table row which has issues in safaridriver - '\
           'Your test should probably be clicking on a table cell like a user would. '\
           'Clicking the first cell in the row instead.'
      return find_css('th:first-child,td:first-child')[0].click(keys, **options)
    end
    raise
  rescue ::Selenium::WebDriver::Error::WebDriverError => e
    raise unless e.instance_of? ::Selenium::WebDriver::Error::WebDriverError

    # Safari doesn't return a specific error here - assume it's an ElementNotInteractableError
    raise ::Selenium::WebDriver::Error::ElementNotInteractableError,
          'Non distinct error raised in #click, translated to ElementNotInteractableError for retry'
  end

  def select_option
    # To optimize to only one check and then click
    selected_or_disabled = driver.execute_script(<<~JS, self)
      arguments[0].closest('select').scrollIntoView();
      return arguments[0].matches(':disabled, select:disabled *, :checked');
    JS
    click unless selected_or_disabled
  end

  def unselect_option
    driver.execute_script("arguments[0].closest('select').scrollIntoView()", self)
    super
  end

  def visible_text
    return '' unless visible?

    vis_text = driver.execute_script('return arguments[0].innerText', self)
    vis_text.squeeze(' ')
            .gsub(/[\ \n]*\n[\ \n]*/, "\n")
            .gsub(/\A[[:space:]&&[^\u00a0]]+/, '')
            .gsub(/[[:space:]&&[^\u00a0]]+\z/, '')
            .tr("\u00a0", ' ')
  end

  def disabled?
    driver.evaluate_script("arguments[0].matches(':disabled, select:disabled *')", self)
  end

  def set_file(value) # rubocop:disable Naming/AccessorMethodName
    # By default files are appended so we have to clear here if its multiple and already set
    native.clear if multiple? && driver.evaluate_script('arguments[0].files', self).any?
    super
  end

  def send_keys(*args)
    if args.none? { |arg| arg.is_a?(Array) || (arg.is_a?(Symbol) && MODIFIER_KEYS.include?(arg)) }
      return super(*args.map { |arg| arg == :space ? ' ' : arg })
    end

    native.click
    _send_keys(args).perform
  end

  def set_text(value, clear: nil, **_unused)
    value = value.to_s
    if clear == :backspace
      # Clear field by sending the correct number of backspace keys.
      backspaces = [:backspace] * self.value.to_s.length
      send_keys([:control, 'e'], *backspaces, value)
    else
      super.tap do
        # React doesn't see the safaridriver element clear
        send_keys(:space, :backspace) if value.to_s.empty? && clear.nil?
      end
    end
  end

  def hover
    # Workaround issue where hover would sometimes fail - possibly due to mouse not having moved
    scroll_if_needed { browser_action.move_to(native, 0, 0).move_to(native).perform }
  end

private

  def _send_keys(keys, actions = browser_action, down_keys = ModifierKeysStack.new)
    case keys
    when *MODIFIER_KEYS
      down_keys.press(keys)
      actions.key_down(keys)
    when String
      keys = keys.upcase if down_keys&.include?(:shift)
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

  MODIFIER_KEYS = %i[control left_control right_control
                     alt left_alt right_alt
                     shift left_shift right_shift
                     meta left_meta right_meta
                     command].freeze
end
