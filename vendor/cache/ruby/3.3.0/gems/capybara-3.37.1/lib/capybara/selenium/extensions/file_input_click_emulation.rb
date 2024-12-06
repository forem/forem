# frozen_string_literal: true

class Capybara::Selenium::Node
  module FileInputClickEmulation
    def click(keys = [], **options)
      super
    rescue Selenium::WebDriver::Error::InvalidArgumentError
      return emulate_click if attaching_file? && visible_file_field?

      raise
    end

  private

    def visible_file_field?
      (attrs(:tagName, :type).map { |val| val&.downcase } == %w[input file]) && visible?
    end

    def attaching_file?
      caller_locations.any? { |cl| cl.base_label == 'attach_file' }
    end

    def emulate_click
      driver.execute_script(<<~JS, self)
        arguments[0].dispatchEvent(
          new MouseEvent('click', {
            view: window,
            bubbles: true,
            cancelable: true
          }));
      JS
    end
  end
end
