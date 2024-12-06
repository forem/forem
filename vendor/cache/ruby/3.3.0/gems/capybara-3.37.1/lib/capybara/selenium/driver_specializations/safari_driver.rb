# frozen_string_literal: true

require 'capybara/selenium/nodes/safari_node'

module Capybara::Selenium::Driver::SafariDriver
  def switch_to_frame(frame)
    return super unless frame == :parent

    # safaridriver/safari has an issue where switch_to_frame(:parent)
    # behaves like switch_to_frame(:top)
    handles = @frame_handles[current_window_handle]
    browser.switch_to.default_content
    handles.tap(&:pop).each { |fh| browser.switch_to.frame(fh.native) }
  end

private

  def build_node(native_node, initial_cache = {})
    ::Capybara::Selenium::SafariNode.new(self, native_node, initial_cache)
  end
end

Capybara::Selenium::Driver.register_specialization(/^(safari|Safari_Technology_Preview)$/,
                                                   Capybara::Selenium::Driver::SafariDriver)
