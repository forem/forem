# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Capybara::Session do
  describe '#new' do
    it 'should raise an error if passed non-existent driver' do
      expect do
        described_class.new(:quox, TestApp).driver
      end.to raise_error(Capybara::DriverNotFoundError)
    end

    it 'verifies a passed app is a rack app' do
      expect do
        described_class.new(:unknown, random: 'hash')
      end.to raise_error TypeError, 'The second parameter to Session::new should be a rack app if passed.'
    end
  end

  context 'current_driver' do
    around do |example|
      orig_driver = Capybara.current_driver
      example.run
      Capybara.current_driver = orig_driver
    end

    it 'is global when threadsafe false' do
      Capybara.threadsafe = false
      Capybara.current_driver = :selenium
      thread = Thread.new do
        Capybara.current_driver = :random
      end
      thread.join
      expect(Capybara.current_driver).to eq :random
    end

    it 'is thread specific threadsafe true' do
      Capybara.threadsafe = true
      Capybara.current_driver = :selenium
      thread = Thread.new do
        Capybara.current_driver = :random
      end
      thread.join
      expect(Capybara.current_driver).to eq :selenium
    end
  end

  context 'session_name' do
    around do |example|
      orig_name = Capybara.session_name
      example.run
      Capybara.session_name = orig_name
    end

    it 'is global when threadsafe false' do
      Capybara.threadsafe = false
      Capybara.session_name = 'sess1'
      thread = Thread.new do
        Capybara.session_name = 'sess2'
      end
      thread.join
      expect(Capybara.session_name).to eq 'sess2'
    end

    it 'is thread specific when threadsafe true' do
      Capybara.threadsafe = true
      Capybara.session_name = 'sess1'
      thread = Thread.new do
        Capybara.session_name = 'sess2'
      end
      thread.join
      expect(Capybara.session_name).to eq 'sess1'
    end
  end

  context 'quit' do
    it 'will reset the driver' do
      session = described_class.new(:rack_test, TestApp)
      driver = session.driver
      session.quit
      expect(session.driver).not_to eql driver
    end

    it 'resets the document' do
      session = described_class.new(:rack_test, TestApp)
      document = session.document
      session.quit
      expect(session.document.base).not_to eql document.base
    end
  end
end
