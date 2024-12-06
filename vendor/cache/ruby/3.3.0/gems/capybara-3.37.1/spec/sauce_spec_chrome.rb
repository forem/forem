# frozen_string_literal: true

require 'spec_helper'
require 'selenium-webdriver'

require 'sauce_whisk'
# require 'shared_selenium_session'
# require 'shared_selenium_node'
# require 'rspec/shared_spec_matchers'

Capybara.register_driver :sauce_chrome do |app|
  options = {
    selenium_version: '3.141.59',
    platform: 'macOS 10.12',
    browser_name: 'chrome',
    version: '65.0',
    name: 'Capybara test',
    build: ENV.fetch('TRAVIS_REPO_SLUG', "Ruby-RSpec-Selenium: Local-#{Time.now.to_i}"),
    username: ENV.fetch('SAUCE_USERNAME', nil),
    access_key: ENV.fetch('SAUCE_ACCESS_KEY', nil)
  }

  options.delete(:browser_name)

  capabilities = Selenium::WebDriver::Remote::Capabilities.chrome(options)
  url = 'https://ondemand.saucelabs.com:443/wd/hub'

  Capybara::Selenium::Driver.new(app,
                                 browser: :remote, url: url,
                                 desired_capabilities: capabilities,
                                 options: Selenium::WebDriver::Chrome::Options.new(args: ['']))
end

CHROME_REMOTE_DRIVER = :sauce_chrome

module TestSessions
  Chrome = Capybara::Session.new(CHROME_REMOTE_DRIVER, TestApp)
end

skipped_tests = %i[response_headers status_code trigger download]

Capybara::SpecHelper.run_specs TestSessions::Chrome, CHROME_REMOTE_DRIVER.to_s, capybara_skip: skipped_tests do |example|
end
