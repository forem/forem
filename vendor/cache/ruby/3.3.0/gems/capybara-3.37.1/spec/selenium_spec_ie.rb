# frozen_string_literal: true

require 'spec_helper'
require 'selenium-webdriver'
require 'shared_selenium_session'
require 'shared_selenium_node'
require 'rspec/shared_spec_matchers'

# if ENV['CI']
#   if ::Selenium::WebDriver::Service.respond_to? :driver_path=
#     ::Selenium::WebDriver::IE::Service
#   else
#     ::Selenium::WebDriver::IE
#   end.driver_path = 'C:\Tools\WebDriver\IEDriverServer.exe'
# end

def selenium_host
  ENV.fetch('SELENIUM_HOST', '192.168.56.102')
end

def selenium_port
  ENV.fetch('SELENIUM_PORT', 4444)
end

def server_host
  ENV.fetch('SERVER_HOST', '10.24.4.135')
end

Capybara.register_driver :selenium_ie do |app|
  # ::Selenium::WebDriver.logger.level = "debug"
  options = ::Selenium::WebDriver::IE::Options.new
  # options.require_window_focus = true
  # options.add_option("log", {"level": "trace"})

  if ENV['REMOTE']
    Capybara.server_host = server_host

    url = "http://#{selenium_host}:#{selenium_port}/wd/hub"
    Capybara::Selenium::Driver.new(app,
                                   browser: :remote,
                                   options: options,
                                   url: url)
  else
    Capybara::Selenium::Driver.new(
      app,
      browser: :ie,
      options: options
    )
  end
end

module TestSessions
  SeleniumIE = Capybara::Session.new(:selenium_ie, TestApp)
end

TestSessions::SeleniumIE.current_window.resize_to(800, 500)

skipped_tests = %i[response_headers status_code trigger modals hover form_attribute windows]

Capybara::SpecHelper.log_selenium_driver_version(Selenium::WebDriver::IE) if ENV['CI']

TestSessions::SeleniumIE.current_window.resize_to(1600, 1200)

Capybara::SpecHelper.run_specs TestSessions::SeleniumIE, 'selenium', capybara_skip: skipped_tests do |example|
  case example.metadata[:full_description]
  when /#refresh it reposts$/
    skip 'IE insists on prompting without providing a way to suppress'
  when /#click_link can download a file$/
    skip 'Not sure how to configure IE for automatic downloading'
  when /#fill_in with Date /
    pending "IE 11 doesn't support date input types"
  when /#click_link_or_button with :disabled option happily clicks on links which incorrectly have the disabled attribute$/
    skip 'IE 11 obeys non-standard disabled attribute on anchor tag'
  when /#click should allow modifiers$/, /#double_click should allow modifiers$/
    pending "Doesn't work with IE for some unknown reason$"
    pending "Doesn't work with IE for some unknown reason$"
  when /#click should allow multiple modifiers$/, /#right_click should allow modifiers$/
    skip "Windows can't :meta click because :meta triggers start menu"
  when /#double_click should allow multiple modifiers$/
    skip "Windows can't :alt double click due to being properties shortcut"
  when /#has_css\? should support case insensitive :class and :id options$/
    pending "IE doesn't support case insensitive CSS selectors"
  when /#reset_session! removes ALL cookies$/
    pending "IE driver doesn't provide a way to remove ALL cookies"
  when /#click_button should send button in document order$/
    pending "IE 11 doesn't support the 'form' attribute"
  when /#click_button should follow permanent redirects that maintain method$/
    pending "Window 7 and 8.1 don't support 308 http status code"
  when /#scroll_to can scroll an element to the center of the viewport$/,
       /#scroll_to can scroll an element to the center of the scrolling element$/
    pending "IE doesn't support ScrollToOptions"
  when /#attach_file with multipart form should fire change once for each set of files uploaded$/,
       /#attach_file with multipart form should fire change once when uploading multiple files from empty$/,
       /#attach_file with multipart form should not break when using HTML5 multiple file input uploading multiple files$/
    pending "IE requires all files be uploaded from same directory. Selenium doesn't provide that." if ENV['REMOTE']
  when %r{#attach_file with multipart form should send content type image/jpeg when uploading an image$}
    pending 'IE gets text/plain type for some reason'
  # when /#click should not retry clicking when wait is disabled$/
  #   Fixed in IEDriverServer 3.141.0.5
  #   pending "IE driver doesn't error when clicking on covered elements, it just clicks the wrong element"
  when /#click should go to the same page if href is blank$/
    pending 'IE treats blank href as a parent request (against HTML spec)'
  when /#attach_file with a block/
    skip 'Hangs IE testing for unknown reason'
  when /drag_to.*HTML5/
    pending "IE doesn't support a DataTransfer constuctor"
  when /template elements should not be visible/
    skip "IE doesn't support template elements"
  when /Element#drop/
    pending "IE doesn't support DataTransfer constructor"
  end
end

RSpec.describe 'Capybara::Session with Internet Explorer', capybara_skip: skipped_tests do # rubocop:disable RSpec/MultipleDescribes
  include Capybara::SpecHelper
  ['Capybara::Session', 'Capybara::Node', Capybara::RSpecMatchers].each do |examples|
    include_examples examples, TestSessions::SeleniumIE, :selenium_ie
  end
end

RSpec.describe Capybara::Selenium::Node do
  it '#right_click should allow modifiers' do
    # pending "Actions API doesn't appear to work for this"
    session = TestSessions::SeleniumIE
    session.visit('/with_js')
    el = session.find(:css, '#click-test')
    el.right_click(:control)
    expect(session).to have_link('Has been control right clicked')
  end

  it '#click should allow multiple modifiers' do
    # pending "Actions API doesn't appear to work for this"
    session = TestSessions::SeleniumIE
    session.visit('with_js')
    # IE triggers system behavior with :meta so can't use those here
    session.find(:css, '#click-test').click(:ctrl, :shift, :alt)
    expect(session).to have_link('Has been alt control shift clicked')
  end

  it '#double_click should allow modifiers' do
    # pending "Actions API doesn't appear to work for this"
    session = TestSessions::SeleniumIE
    session.visit('/with_js')
    session.find(:css, '#click-test').double_click(:shift)
    expect(session).to have_link('Has been shift double clicked')
  end
end
