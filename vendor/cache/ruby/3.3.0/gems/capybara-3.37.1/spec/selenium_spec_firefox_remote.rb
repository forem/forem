# frozen_string_literal: true

require 'spec_helper'
require 'selenium-webdriver'
require 'shared_selenium_session'
require 'shared_selenium_node'
require 'rspec/shared_spec_matchers'

def selenium_host
  ENV.fetch('SELENIUM_HOST', '0.0.0.0')
end

def selenium_port
  ENV.fetch('SELENIUM_PORT', 4445)
end

def ensure_selenium_running!
  timer = Capybara::Helpers.timer(expire_in: 20)
  begin
    TCPSocket.open(selenium_host, selenium_port)
  rescue StandardError
    if timer.expired?
      raise 'Selenium is not running. ' \
            "You can run a selenium server easily with: \n" \
            '  $ docker-compose up -d selenium_firefox'
    else
      puts 'Waiting for Selenium docker instance...'
      sleep 1
      retry
    end
  end
end

Capybara.register_driver :selenium_firefox_remote do |app|
  ensure_selenium_running!

  url = "http://#{selenium_host}:#{selenium_port}/wd/hub"
  browser_options = ::Selenium::WebDriver::Firefox::Options.new

  Capybara::Selenium::Driver.new app,
                                 browser: :remote,
                                 desired_capabilities: :firefox,
                                 options: browser_options,
                                 url: url
end

FIREFOX_REMOTE_DRIVER = :selenium_firefox_remote

module TestSessions
  RemoteFirefox = Capybara::Session.new(FIREFOX_REMOTE_DRIVER, TestApp)
end

skipped_tests = %i[response_headers status_code trigger download]

Capybara::SpecHelper.run_specs TestSessions::RemoteFirefox, FIREFOX_REMOTE_DRIVER.to_s, capybara_skip: skipped_tests do |example|
  case example.metadata[:full_description]
  when 'Capybara::Session selenium_firefox_remote node #click should allow multiple modifiers'
    skip "Firefox doesn't generate an event for shift+control+click" if firefox_gte?(62, @session)
  when 'Capybara::Session selenium_firefox_remote #accept_prompt should accept the prompt with a blank response when there is a default'
    pending "Geckodriver doesn't set a blank response in FF < 63 - https://bugzilla.mozilla.org/show_bug.cgi?id=1486485" if firefox_lt?(63, @session)
  when 'Capybara::Session selenium_firefox_remote #attach_file with multipart form should fire change once when uploading multiple files from empty'
    pending "FF < 62 doesn't support setting all files at once" if firefox_lt?(62, @session)
  when 'Capybara::Session selenium_firefox_remote #reset_session! removes ALL cookies'
    pending "Geckodriver doesn't provide a way to remove cookies outside the current domain"
  when /#accept_confirm should work with nested modals$/
    # skip because this is timing based and hence flaky when set to pending
    skip 'Broken in FF 63 - https://bugzilla.mozilla.org/show_bug.cgi?id=1487358' if firefox_gte?(63, @session)
  end
end

RSpec.describe 'Capybara::Session with remote firefox' do
  include Capybara::SpecHelper
  ['Capybara::Session', 'Capybara::Node', Capybara::RSpecMatchers].each do |examples|
    include_examples examples, TestSessions::RemoteFirefox, FIREFOX_REMOTE_DRIVER
  end

  it 'is considered to be firefox' do
    expect(session.driver.browser.browser).to eq :firefox
  end
end
