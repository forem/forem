# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Capybara do
  describe 'default_max_wait_time' do
    before { @previous_default_time = described_class.default_max_wait_time }

    after { described_class.default_max_wait_time = @previous_default_time } # rubocop:disable RSpec/InstanceVariable

    it 'should be changeable' do
      expect(described_class.default_max_wait_time).not_to eq(5)
      described_class.default_max_wait_time = 5
      expect(described_class.default_max_wait_time).to eq(5)
    end
  end

  describe '.register_driver' do
    it 'should add a new driver' do
      described_class.register_driver :schmoo do |app|
        Capybara::RackTest::Driver.new(app)
      end
      session = Capybara::Session.new(:schmoo, TestApp)
      session.visit('/')
      expect(session.body).to include('Hello world!')
    end
  end

  describe '.register_server' do
    it 'should add a new server' do
      described_class.register_server :blob do |_app, _port, _host|
        # do nothing
      end

      expect(described_class.servers[:blob]).to be_truthy
    end
  end

  describe '.server' do
    after do
      described_class.server = :default
    end

    it 'should default to a proc that calls run_default_server' do
      mock_app = Object.new
      allow(described_class).to receive(:run_default_server).and_return(true)
      described_class.server.call(mock_app, 8000)
      expect(described_class).to have_received(:run_default_server).with(mock_app, 8000)
    end

    it 'should return a custom server proc' do
      server = ->(_app, _port) {}
      described_class.register_server :custom, &server
      described_class.server = :custom
      expect(described_class.server).to eq(server)
    end

    it 'should have :webrick registered' do
      expect(described_class.servers[:webrick]).not_to be_nil
    end

    it 'should have :puma registered' do
      expect(described_class.servers[:puma]).not_to be_nil
    end
  end

  describe 'server=' do
    after do
      described_class.server = :default
    end

    it 'accepts a proc' do
      server = ->(_app, _port) {}
      described_class.server = server
      expect(described_class.server).to eq server
    end
  end

  describe 'app_host' do
    after do
      described_class.app_host = nil
    end

    it 'should warn if not a valid URL' do
      expect { described_class.app_host = 'www.example.com' }.to raise_error(ArgumentError, /Capybara\.app_host should be set to a url/)
    end

    it 'should not warn if a valid URL' do
      expect { described_class.app_host = 'http://www.example.com' }.not_to raise_error
    end

    it 'should not warn if nil' do
      expect { described_class.app_host = nil }.not_to raise_error
    end
  end

  describe 'default_host' do
    around do |test|
      old_default = described_class.default_host
      test.run
      described_class.default_host = old_default
    end

    it 'should raise if not a valid URL' do
      expect { described_class.default_host = 'www.example.com' }.to raise_error(ArgumentError, /Capybara\.default_host should be set to a url/)
    end

    it 'should not warn if a valid URL' do
      expect { described_class.default_host = 'http://www.example.com' }.not_to raise_error
    end
  end
end
