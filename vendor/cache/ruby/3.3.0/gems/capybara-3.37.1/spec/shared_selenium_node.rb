# frozen_string_literal: true

require 'spec_helper'
require 'selenium-webdriver'

RSpec.shared_examples 'Capybara::Node' do |session, _mode|
  let(:session) { session }

  describe '#content_editable?' do
    it 'returns true when the element is content editable' do
      session.visit('/with_js')
      expect(session.find(:css, '#existing_content_editable').base.content_editable?).to be true
      expect(session.find(:css, '#existing_content_editable_child').base.content_editable?).to be true
    end

    it 'returns false when the element is not content editable' do
      session.visit('/with_js')
      expect(session.find(:css, '#drag').base.content_editable?).to be false
    end
  end

  describe '#send_keys' do
    it 'should process space' do
      session.visit('/form')
      session.find(:css, '#address1_city').send_keys('ocean', [:shift, :space, 'side'])
      expect(session.find(:css, '#address1_city').value).to eq 'ocean SIDE'
    end
  end

  describe '#[]' do
    it 'should work for spellcheck' do
      session.visit('/with_html')
      expect(session.find('//input[@spellcheck="TRUE"]')[:spellcheck]).to eq('true')
      expect(session.find('//input[@spellcheck="FALSE"]')[:spellcheck]).to eq('false')
    end
  end

  describe '#set' do
    it 'respects maxlength when using rapid set' do
      session.visit('/form')
      inp = session.find(:css, '#long_length')
      value = (0...50).map { |i| ((i % 26) + 65).chr }.join
      inp.set(value, rapid: true)
      expect(inp.value).to eq value[0...35]
    end
  end

  describe '#visible?' do
    let(:bridge) do
      session.driver.browser.send(:bridge)
    end

    around do |example|
      native_displayed = session.driver.options[:native_displayed]
      example.run
      session.driver.options[:native_displayed] = native_displayed
    end

    before do
      allow(bridge).to receive(:execute_atom).and_call_original
    end

    it 'will use native displayed if told to' do
      session.driver.options[:native_displayed] = true
      session.visit('/form')
      session.find(:css, '#address1_city', visible: true)

      expect(bridge).not_to have_received(:execute_atom)
    end

    it "won't use native displayed if told not to" do
      session.driver.options[:native_displayed] = false
      session.visit('/form')
      session.find(:css, '#address1_city', visible: true)

      expect(bridge).to have_received(:execute_atom).with(:isDisplayed, any_args)
    end
  end
end
