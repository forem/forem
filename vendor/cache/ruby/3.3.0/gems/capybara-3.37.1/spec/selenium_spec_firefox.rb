# frozen_string_literal: true

require 'spec_helper'
require 'selenium-webdriver'
require 'shared_selenium_session'
require 'shared_selenium_node'
require 'rspec/shared_spec_matchers'

browser_options = ::Selenium::WebDriver::Firefox::Options.new
browser_options.headless! if ENV['HEADLESS']
# browser_options.add_option("log", {"level": "trace"})

browser_options.profile = Selenium::WebDriver::Firefox::Profile.new.tap do |profile|
  profile['browser.download.dir'] = Capybara.save_path
  profile['browser.download.folderList'] = 2
  profile['browser.helperApps.neverAsk.saveToDisk'] = 'text/csv'
  profile['browser.startup.homepage'] = 'about:blank' # workaround bug in Selenium 4 alpha4-7
  profile['accessibility.tabfocus'] = 7 # make tab move over links too
end

Capybara.register_driver :selenium_firefox do |app|
  # ::Selenium::WebDriver.logger.level = "debug"
  version = Capybara::Selenium::Driver.load_selenium
  options_key = Capybara::Selenium::Driver::CAPS_VERSION.satisfied_by?(version) ? :capabilities : :options
  driver_options = { browser: :firefox, timeout: 31 }.tap do |opts|
    opts[options_key] = browser_options
    # Get a trace level log from geckodriver
    # :driver_opts => { args: ['-vv'] }
  end

  Capybara::Selenium::Driver.new(app, **driver_options)
end

Capybara.register_driver :selenium_firefox_not_clear_storage do |app|
  version = Capybara::Selenium::Driver.load_selenium
  options_key = Capybara::Selenium::Driver::CAPS_VERSION.satisfied_by?(version) ? :capabilities : :options
  driver_options = { browser: :firefox, clear_local_storage: false, clear_session_storage: false }.tap do |opts|
    opts[options_key] = browser_options
  end

  Capybara::Selenium::Driver.new(app, **driver_options)
end

module TestSessions
  SeleniumFirefox = Capybara::Session.new(:selenium_firefox, TestApp)
end

skipped_tests = %i[response_headers status_code trigger]

Capybara::SpecHelper.log_selenium_driver_version(Selenium::WebDriver::Firefox) if ENV['CI']

Capybara::SpecHelper.run_specs TestSessions::SeleniumFirefox, 'selenium', capybara_skip: skipped_tests do |example|
  case example.metadata[:full_description]
  when 'Capybara::Session selenium node #click should allow multiple modifiers'
    pending "Firefox on OSX doesn't generate an event for shift+control+click" if firefox_gte?(62, @session) && Selenium::WebDriver::Platform.mac?
  when /^Capybara::Session selenium node #double_click/
    pending "selenium-webdriver/geckodriver doesn't generate double click event" if firefox_lt?(59, @session)
  when 'Capybara::Session selenium #accept_prompt should accept the prompt with a blank response when there is a default'
    pending "Geckodriver doesn't set a blank response in FF < 63 - https://bugzilla.mozilla.org/show_bug.cgi?id=1486485" if firefox_lt?(63, @session)
  when 'Capybara::Session selenium #attach_file with multipart form should fire change once when uploading multiple files from empty'
    pending "FF < 62 doesn't support setting all files at once" if firefox_lt?(62, @session)
  when 'Capybara::Session selenium #accept_confirm should work with nested modals'
    skip 'Broken in 63 <= FF < 69 - https://bugzilla.mozilla.org/show_bug.cgi?id=1487358' if firefox_gte?(63, @session) && firefox_lt?(69, @session)
    skip 'Hangs in 69 <= FF < 71 - Dont know what issue for this - previous issue was closed as fixed but it is not' if firefox_gte?(69, @session) && firefox_lt?(71, @session)
    skip 'Broken again intermittently in FF 71 - jus skip it'
  when 'Capybara::Session selenium #click_link can download a file'
    skip 'Need to figure out testing of file downloading on windows platform' if Gem.win_platform?
  when 'Capybara::Session selenium #reset_session! removes ALL cookies'
    pending "Geckodriver doesn't provide a way to remove cookies outside the current domain"
  when /drag_to.*HTML5/
    pending "Firefox < 62 doesn't support a DataTransfer constuctor" if firefox_lt?(62.0, @session)
  when 'Capybara::Session selenium #accept_alert should handle the alert if the page changes',
       'Capybara::Session selenium #accept_alert with an asynchronous alert should accept the alert'
    skip 'No clue what Firefox is doing here - works fine on MacOS locally'
  when 'Capybara::Session selenium node #shadow_root should get the shadow root',
       'Capybara::Session selenium node #shadow_root should find elements inside the shadow dom using CSS',
       'Capybara::Session selenium node #shadow_root should find nested shadow roots'
    pending "Firefox doesn't yet have W3C shadow root support"
  end
end

RSpec.describe 'Capybara::Session with firefox' do # rubocop:disable RSpec/MultipleDescribes
  include Capybara::SpecHelper
  ['Capybara::Session', 'Capybara::Node', Capybara::RSpecMatchers].each do |examples|
    include_examples examples, TestSessions::SeleniumFirefox, :selenium_firefox
  end

  describe 'filling in Firefox-specific date and time fields with keystrokes' do
    let(:datetime) { Time.new(1983, 6, 19, 6, 30) }
    let(:session) { TestSessions::SeleniumFirefox }

    before do
      session.visit('/form')
    end

    it 'should fill in a date input with a String' do
      session.fill_in('form_date', with: datetime.to_date.iso8601)
      session.click_button('awesome')
      expect(Date.parse(extract_results(session)['date'])).to eq datetime.to_date
    end

    it 'should fill in a time input with a String' do
      session.fill_in('form_time', with: datetime.to_time.strftime('%T'))
      session.click_button('awesome')
      results = extract_results(session)['time']
      expect(Time.parse(results).strftime('%r')).to eq datetime.strftime('%r')
    end

    it 'should fill in a datetime input with a String' do
      pending 'Need to figure out what string format this will actually accept'
      session.fill_in('form_datetime', with: datetime.iso8601)
      session.click_button('awesome')
      expect(Time.parse(extract_results(session)['datetime'])).to eq datetime
    end
  end
end

RSpec.describe Capybara::Selenium::Driver do
  let(:driver) { described_class.new(TestApp, browser: :firefox, options: browser_options) }

  describe '#quit' do
    it 'should reset browser when quit' do
      expect(driver.browser).to be_truthy
      driver.quit
      # access instance variable directly so we don't create a new browser instance
      expect(driver.instance_variable_get(:@browser)).to be_nil
    end

    context 'with errors' do
      let!(:original_browser) { driver.browser }

      after do
        # Ensure browser is actually quit so we don't leave hanging processe
        RSpec::Mocks.space.proxy_for(original_browser).reset
        original_browser.quit
      end

      it 'warns UnknownError returned during quit because the browser is probably already gone' do
        allow(driver).to receive(:warn)
        allow(driver.browser).to(
          receive(:quit)
          .and_raise(Selenium::WebDriver::Error::UnknownError, 'random message')
        )

        expect { driver.quit }.not_to raise_error
        expect(driver.instance_variable_get(:@browser)).to be_nil
        expect(driver).to have_received(:warn).with(/random message/)
      end

      it 'ignores silenced UnknownError returned during quit because the browser is almost definitely already gone' do
        allow(driver).to receive(:warn)
        allow(driver.browser).to(
          receive(:quit)
          .and_raise(Selenium::WebDriver::Error::UnknownError, 'Error communicating with the remote browser')
        )

        expect { driver.quit }.not_to raise_error
        expect(driver.instance_variable_get(:@browser)).to be_nil
        expect(driver).not_to have_received(:warn)
      end
    end
  end

  context 'storage' do
    describe '#reset!' do
      it 'clears storage by default' do
        session = TestSessions::SeleniumFirefox
        session.visit('/with_js')
        session.find(:css, '#set-storage').click
        session.reset!
        session.visit('/with_js')
        expect(session.driver.browser.local_storage.keys).to be_empty
        expect(session.driver.browser.session_storage.keys).to be_empty
      end

      it 'does not clear storage when false' do
        session = Capybara::Session.new(:selenium_firefox_not_clear_storage, TestApp)
        session.visit('/with_js')
        session.find(:css, '#set-storage').click
        session.reset!
        session.visit('/with_js')
        expect(session.driver.browser.local_storage.keys).not_to be_empty
        expect(session.driver.browser.session_storage.keys).not_to be_empty
      end
    end
  end

  context 'timeout' do
    it 'sets the http client read timeout' do
      expect(TestSessions::SeleniumFirefox.driver.browser.send(:bridge).http.read_timeout).to eq 31
    end
  end
end

RSpec.describe Capybara::Selenium::Node do
  describe '#click' do
    it 'warns when attempting on a table row' do
      session = TestSessions::SeleniumFirefox
      session.visit('/tables')
      tr = session.find(:css, '#agent_table tr:first-child')
      allow(tr.base).to receive(:warn)
      tr.click
      expect(tr.base).to have_received(:warn).with(/Clicking the first cell in the row instead/)
    end

    it 'should allow multiple modifiers', requires: [:js] do
      session = TestSessions::SeleniumFirefox
      session.visit('with_js')
      # Firefox v62+ doesn't generate an event for control+shift+click
      session.find(:css, '#click-test').click(:alt, :ctrl, :meta)
      # it also triggers a contextmenu event when control is held so don't check click type
      expect(session).to have_link('Has been alt control meta')
    end
  end
end
