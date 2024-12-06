# frozen_string_literal: true

class Capybara::Driver::Base
  attr_writer :session

  def current_url
    raise NotImplementedError
  end

  def visit(path)
    raise NotImplementedError
  end

  def refresh
    raise NotImplementedError
  end

  def find_xpath(query, **options)
    raise NotImplementedError
  end

  def find_css(query, **options)
    raise NotImplementedError
  end

  def html
    raise NotImplementedError
  end

  def go_back
    raise Capybara::NotSupportedByDriverError, 'Capybara::Driver::Base#go_back'
  end

  def go_forward
    raise Capybara::NotSupportedByDriverError, 'Capybara::Driver::Base#go_forward'
  end

  def execute_script(script, *args)
    raise Capybara::NotSupportedByDriverError, 'Capybara::Driver::Base#execute_script'
  end

  def evaluate_script(script, *args)
    raise Capybara::NotSupportedByDriverError, 'Capybara::Driver::Base#evaluate_script'
  end

  def evaluate_async_script(script, *args)
    raise Capybara::NotSupportedByDriverError, 'Capybara::Driver::Base#evaluate_script_asnyc'
  end

  def save_screenshot(path, **options)
    raise Capybara::NotSupportedByDriverError, 'Capybara::Driver::Base#save_screenshot'
  end

  def response_headers
    raise Capybara::NotSupportedByDriverError, 'Capybara::Driver::Base#response_headers'
  end

  def status_code
    raise Capybara::NotSupportedByDriverError, 'Capybara::Driver::Base#status_code'
  end

  def send_keys(*)
    raise Capybara::NotSupportedByDriverError, 'Capybara::Driver::Base#send_keys'
  end

  def active_element
    raise Capybara::NotSupportedByDriverError, 'Capybara::Driver::Base#active_element'
  end

  ##
  #
  # @param frame [Capybara::Node::Element, :parent, :top]  The iframe element to switch to
  #
  def switch_to_frame(frame)
    raise Capybara::NotSupportedByDriverError, 'Capybara::Driver::Base#switch_to_frame'
  end

  def frame_title
    find_xpath('/html/head/title').map(&:all_text).first.to_s
  end

  def frame_url
    evaluate_script('document.location.href')
  rescue Capybara::NotSupportedByDriverError
    raise Capybara::NotSupportedByDriverError, 'Capybara::Driver::Base#frame_title'
  end

  def current_window_handle
    raise Capybara::NotSupportedByDriverError, 'Capybara::Driver::Base#current_window_handle'
  end

  def window_size(handle)
    raise Capybara::NotSupportedByDriverError, 'Capybara::Driver::Base#window_size'
  end

  def resize_window_to(handle, width, height)
    raise Capybara::NotSupportedByDriverError, 'Capybara::Driver::Base#resize_window_to'
  end

  def maximize_window(handle)
    raise Capybara::NotSupportedByDriverError, 'Capybara::Driver::Base#maximize_window'
  end

  def fullscreen_window(handle)
    raise Capybara::NotSupportedByDriverError, 'Capybara::Driver::Base#fullscreen_window'
  end

  def close_window(handle)
    raise Capybara::NotSupportedByDriverError, 'Capybara::Driver::Base#close_window'
  end

  def window_handles
    raise Capybara::NotSupportedByDriverError, 'Capybara::Driver::Base#window_handles'
  end

  def open_new_window
    raise Capybara::NotSupportedByDriverError, 'Capybara::Driver::Base#open_new_window'
  end

  def switch_to_window(handle)
    raise Capybara::NotSupportedByDriverError, 'Capybara::Driver::Base#switch_to_window'
  end

  def no_such_window_error
    raise Capybara::NotSupportedByDriverError, 'Capybara::Driver::Base#no_such_window_error'
  end

  ##
  #
  # Execute the block, and then accept the modal opened.
  # @param type [:alert, :confirm, :prompt]
  # @option options [Numeric] :wait  How long to wait for the modal to appear after executing the block.
  # @option options [String, Regexp] :text  Text to verify is in the message shown in the modal
  # @option options [String] :with  Text to fill in in the case of a prompt
  # @return [String]  the message shown in the modal
  # @raise [Capybara::ModalNotFound]  if modal dialog hasn't been found
  #
  def accept_modal(type, **options, &blk)
    raise Capybara::NotSupportedByDriverError, 'Capybara::Driver::Base#accept_modal'
  end

  ##
  #
  # Execute the block, and then dismiss the modal opened.
  # @param type [:alert, :confirm, :prompt]
  # @option options [Numeric] :wait  How long to wait for the modal to appear after executing the block.
  # @option options [String, Regexp] :text  Text to verify is in the message shown in the modal
  # @return [String]  the message shown in the modal
  # @raise [Capybara::ModalNotFound]  if modal dialog hasn't been found
  #
  def dismiss_modal(type, **options, &blk)
    raise Capybara::NotSupportedByDriverError, 'Capybara::Driver::Base#dismiss_modal'
  end

  def invalid_element_errors
    []
  end

  def wait?
    false
  end

  def reset!; end

  def needs_server?
    false
  end

  def session_options
    session&.config || Capybara.session_options
  end

private

  def session
    @session ||= nil
  end
end
