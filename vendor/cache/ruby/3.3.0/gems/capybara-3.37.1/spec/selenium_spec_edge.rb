# frozen_string_literal: true

require 'spec_helper'
require 'selenium-webdriver'
require 'shared_selenium_session'
require 'shared_selenium_node'
require 'rspec/shared_spec_matchers'

# unless ENV['CI']
#   Selenium::WebDriver::Edge::Service.driver_path = '/usr/local/bin/msedgedriver'
# end

if ::Selenium::WebDriver::Platform.mac?
  Selenium::WebDriver::EdgeChrome.path = '/Applications/Microsoft Edge Dev.app/Contents/MacOS/Microsoft Edge Dev'
end

Capybara.register_driver :selenium_edge do |app|
  # ::Selenium::WebDriver.logger.level = "debug"
  # If we don't create an options object the path set above won't be used
  browser_options = ::Selenium::WebDriver::EdgeChrome::Options.new
  Capybara::Selenium::Driver.new(app, browser: :edge_chrome, options: browser_options).tap do |driver|
    driver.browser
    driver.download_path = Capybara.save_path
  end
end

module TestSessions
  SeleniumEdge = Capybara::Session.new(:selenium_edge, TestApp)
end

skipped_tests = %i[response_headers status_code trigger]

Capybara::SpecHelper.log_selenium_driver_version(Selenium::WebDriver::EdgeChrome) if ENV['CI']

Capybara::SpecHelper.run_specs TestSessions::SeleniumEdge, 'selenium', capybara_skip: skipped_tests do |example|
  case example.metadata[:full_description]
  when 'Capybara::Session selenium #attach_file with a block can upload by clicking the file input'
    pending "EdgeChrome doesn't allow clicking on file inputs"
  end
end

RSpec.describe 'Capybara::Session with Edge', capybara_skip: skipped_tests do
  include Capybara::SpecHelper
  ['Capybara::Session', 'Capybara::Node', Capybara::RSpecMatchers].each do |examples|
    include_examples examples, TestSessions::SeleniumEdge, :selenium_edge
  end
end
