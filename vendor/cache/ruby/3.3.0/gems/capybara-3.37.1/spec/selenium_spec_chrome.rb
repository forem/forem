# frozen_string_literal: true

require 'spec_helper'
require 'selenium-webdriver'
require 'shared_selenium_session'
require 'shared_selenium_node'
require 'rspec/shared_spec_matchers'

CHROME_DRIVER = :selenium_chrome

Selenium::WebDriver::Chrome.path = '/usr/bin/google-chrome-beta' if ENV.fetch('CI', nil) && ENV.fetch('CHROME_BETA', nil)

browser_options = ::Selenium::WebDriver::Chrome::Options.new
browser_options.headless! if ENV['HEADLESS']

# Chromedriver 77 requires setting this for headless mode on linux
# Different versions of Chrome/selenium-webdriver require setting differently - jus set them all
browser_options.add_preference('download.default_directory', Capybara.save_path)
browser_options.add_preference(:download, default_directory: Capybara.save_path)

Capybara.register_driver :selenium_chrome do |app|
  version = Capybara::Selenium::Driver.load_selenium
  options_key = Capybara::Selenium::Driver::CAPS_VERSION.satisfied_by?(version) ? :capabilities : :options
  driver_options = { browser: :chrome, timeout: 30 }.tap do |opts|
    opts[options_key] = browser_options
  end

  Capybara::Selenium::Driver.new(app, **driver_options).tap do |driver|
    # Set download dir for Chrome < 77
    driver.browser.download_path = Capybara.save_path
  end
end

Capybara.register_driver :selenium_chrome_not_clear_storage do |app|
  version = Capybara::Selenium::Driver.load_selenium
  options_key = Capybara::Selenium::Driver::CAPS_VERSION.satisfied_by?(version) ? :capabilities : :options
  chrome_options = { browser: :chrome, clear_local_storage: false, clear_session_storage: false }.tap do |opts|
    opts[options_key] = browser_options
  end

  Capybara::Selenium::Driver.new(app, **chrome_options)
end

Capybara.register_driver :selenium_chrome_not_clear_session_storage do |app|
  version = Capybara::Selenium::Driver.load_selenium
  options_key = Capybara::Selenium::Driver::CAPS_VERSION.satisfied_by?(version) ? :capabilities : :options
  chrome_options = { browser: :chrome, clear_session_storage: false }.tap do |opts|
    opts[options_key] = browser_options
  end

  Capybara::Selenium::Driver.new(app, **chrome_options)
end

Capybara.register_driver :selenium_chrome_not_clear_local_storage do |app|
  version = Capybara::Selenium::Driver.load_selenium
  options_key = Capybara::Selenium::Driver::CAPS_VERSION.satisfied_by?(version) ? :capabilities : :options
  chrome_options = { browser: :chrome, clear_local_storage: false }.tap do |opts|
    opts[options_key] = browser_options
  end
  Capybara::Selenium::Driver.new(app, **chrome_options)
end

Capybara.register_driver :selenium_driver_subclass_with_chrome do |app|
  version = Capybara::Selenium::Driver.load_selenium
  options_key = Capybara::Selenium::Driver::CAPS_VERSION.satisfied_by?(version) ? :capabilities : :options
  subclass = Class.new(Capybara::Selenium::Driver)
  chrome_options = { browser: :chrome, timeout: 30 }.tap do |opts|
    opts[options_key] = browser_options
  end

  subclass.new(app, **chrome_options)
end

module TestSessions
  Chrome = Capybara::Session.new(CHROME_DRIVER, TestApp)
end

skipped_tests = %i[response_headers status_code trigger]

Capybara::SpecHelper.log_selenium_driver_version(Selenium::WebDriver::Chrome) if ENV['CI']

Capybara::SpecHelper.run_specs TestSessions::Chrome, CHROME_DRIVER.to_s, capybara_skip: skipped_tests do |example|
  case example.metadata[:full_description]
  when /#click_link can download a file$/
    skip 'Need to figure out testing of file downloading on windows platform' if Gem.win_platform?
  when /Capybara::Session selenium_chrome Capybara::Window#maximize/
    pending "Chrome headless doesn't support maximize" if ENV['HEADLESS']
  end
end

RSpec.describe 'Capybara::Session with chrome' do
  include Capybara::SpecHelper
  ['Capybara::Session', 'Capybara::Node', Capybara::RSpecMatchers].each do |examples|
    include_examples examples, TestSessions::Chrome, CHROME_DRIVER
  end

  context 'storage' do
    describe '#reset!' do
      it 'clears storage by default' do
        session = TestSessions::Chrome
        session.visit('/with_js')
        session.find(:css, '#set-storage').click
        session.reset!
        session.visit('/with_js')
        expect(session.evaluate_script('Object.keys(localStorage)')).to be_empty
        expect(session.evaluate_script('Object.keys(sessionStorage)')).to be_empty
      end

      it 'does not clear storage when false' do
        session = Capybara::Session.new(:selenium_chrome_not_clear_storage, TestApp)
        session.visit('/with_js')
        session.find(:css, '#set-storage').click
        session.reset!
        session.visit('/with_js')
        expect(session.evaluate_script('Object.keys(localStorage)')).not_to be_empty
        expect(session.evaluate_script('Object.keys(sessionStorage)')).not_to be_empty
      end

      it 'can not clear session storage' do
        session = Capybara::Session.new(:selenium_chrome_not_clear_session_storage, TestApp)
        session.visit('/with_js')
        session.find(:css, '#set-storage').click
        session.reset!
        session.visit('/with_js')
        expect(session.evaluate_script('Object.keys(localStorage)')).to be_empty
        expect(session.evaluate_script('Object.keys(sessionStorage)')).not_to be_empty
      end

      it 'can not clear local storage' do
        session = Capybara::Session.new(:selenium_chrome_not_clear_local_storage, TestApp)
        session.visit('/with_js')
        session.find(:css, '#set-storage').click
        session.reset!
        session.visit('/with_js')
        expect(session.evaluate_script('Object.keys(localStorage)')).not_to be_empty
        expect(session.evaluate_script('Object.keys(sessionStorage)')).to be_empty
      end
    end
  end

  context 'timeout' do
    it 'sets the http client read timeout' do
      expect(TestSessions::Chrome.driver.browser.send(:bridge).http.read_timeout).to eq 30
    end
  end

  describe 'filling in Chrome-specific date and time fields with keystrokes' do
    let(:datetime) { Time.new(1983, 6, 19, 6, 30) }
    let(:session) { TestSessions::Chrome }

    before do
      session.visit('/form')
    end

    it 'should fill in a date input with a String' do
      session.fill_in('form_date', with: '06/19/1983')
      session.click_button('awesome')
      expect(Date.parse(extract_results(session)['date'])).to eq datetime.to_date
    end

    it 'should fill in a time input with a String' do
      session.fill_in('form_time', with: '06:30A')
      session.click_button('awesome')
      results = extract_results(session)['time']
      expect(Time.parse(results).strftime('%r')).to eq datetime.strftime('%r')
    end

    it 'should fill in a datetime input with a String' do
      session.fill_in('form_datetime', with: "06/19/1983\t06:30A")
      session.click_button('awesome')
      expect(Time.parse(extract_results(session)['datetime'])).to eq datetime
    end
  end

  describe 'using subclass of selenium driver' do
    it 'works' do
      session = Capybara::Session.new(:selenium_driver_subclass_with_chrome, TestApp)
      session.visit('/form')
      expect(session).to have_current_path('/form')
    end
  end

  describe 'log access' do
    let(:logs) do
      session.driver.browser.then do |chrome_driver|
        chrome_driver.respond_to?(:logs) ? chrome_driver : chrome_driver.manage
      end.logs
    end

    it 'does not error getting log types' do
      expect do
        logs.available_types
      end.not_to raise_error
    end

    it 'does not error when getting logs' do
      expect do
        logs.get(:browser)
      end.not_to raise_error
    end
  end

  def chromedriver_version
    Gem::Version.new(session.driver.browser.capabilities['chrome']['chromedriverVersion'].split[0])
  end
end
