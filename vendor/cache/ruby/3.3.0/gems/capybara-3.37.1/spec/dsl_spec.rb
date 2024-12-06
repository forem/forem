# frozen_string_literal: true

require 'spec_helper'
require 'capybara/dsl'

class TestClass
  include Capybara::DSL
end

Capybara::SpecHelper.run_specs TestClass.new, 'DSL', capybara_skip: %i[
  js modals screenshot frames windows send_keys server hover about_scheme psc download css driver scroll spatial html_validation shadow_dom active_element
] do |example|
  case example.metadata[:full_description]
  when /has_css\? should support case insensitive :class and :id options/
    pending "Nokogiri doesn't support case insensitive CSS attribute matchers"
  when /#click_button should follow permanent redirects that maintain method/
    pending "Rack < 2 doesn't support 308" if Gem.loaded_specs['rack'].version < Gem::Version.new('2.0.0')
  end
end

RSpec.describe Capybara::DSL do
  before do
    Capybara.use_default_driver
  end

  after do
    Capybara.session_name = nil
    Capybara.default_driver = nil
    Capybara.javascript_driver = nil
    Capybara.use_default_driver
    Capybara.app = TestApp
  end

  describe '#default_driver' do
    it 'should default to rack_test' do
      expect(Capybara.default_driver).to eq(:rack_test)
    end

    it 'should be changeable' do
      Capybara.default_driver = :culerity
      expect(Capybara.default_driver).to eq(:culerity)
    end
  end

  describe '#current_driver' do
    it 'should default to the default driver' do
      expect(Capybara.current_driver).to eq(:rack_test)
      Capybara.default_driver = :culerity
      expect(Capybara.current_driver).to eq(:culerity)
    end

    it 'should be changeable' do
      Capybara.current_driver = :culerity
      expect(Capybara.current_driver).to eq(:culerity)
    end
  end

  describe '#javascript_driver' do
    it 'should default to selenium' do
      expect(Capybara.javascript_driver).to eq(:selenium)
    end

    it 'should be changeable' do
      Capybara.javascript_driver = :culerity
      expect(Capybara.javascript_driver).to eq(:culerity)
    end
  end

  describe '#use_default_driver' do
    it 'should restore the default driver' do
      Capybara.current_driver = :culerity
      Capybara.use_default_driver
      expect(Capybara.current_driver).to eq(:rack_test)
    end
  end

  describe '#using_driver' do
    before do
      expect(Capybara.current_driver).not_to eq(:selenium) # rubocop:disable RSpec/ExpectInHook
    end

    it 'should set the driver using Capybara.current_driver=' do
      driver = nil
      Capybara.using_driver(:selenium) { driver = Capybara.current_driver }
      expect(driver).to eq(:selenium)
    end

    it 'should return the driver to default if it has not been changed' do
      Capybara.using_driver(:selenium) do
        expect(Capybara.current_driver).to eq(:selenium)
      end
      expect(Capybara.current_driver).to eq(Capybara.default_driver)
    end

    it 'should reset the driver even if an exception occurs' do
      driver_before_block = Capybara.current_driver
      begin
        Capybara.using_driver(:selenium) { raise 'ohnoes!' }
      rescue Exception # rubocop:disable Lint/RescueException,Lint/SuppressedException
      end
      expect(Capybara.current_driver).to eq(driver_before_block)
    end

    it 'should return the driver to what it was previously' do
      Capybara.current_driver = :selenium
      Capybara.using_driver(:culerity) do
        Capybara.using_driver(:rack_test) do
          expect(Capybara.current_driver).to eq(:rack_test)
        end
        expect(Capybara.current_driver).to eq(:culerity)
      end
      expect(Capybara.current_driver).to eq(:selenium)
    end

    it 'should yield the passed block' do
      called = false
      Capybara.using_driver(:selenium) { called = true }
      expect(called).to be(true)
    end
  end

  # rubocop:disable RSpec/InstanceVariable
  describe '#using_wait_time' do
    before { @previous_wait_time = Capybara.default_max_wait_time }

    after { Capybara.default_max_wait_time = @previous_wait_time }

    it 'should switch the wait time and switch it back' do
      in_block = nil
      Capybara.using_wait_time 6 do
        in_block = Capybara.default_max_wait_time
      end
      expect(in_block).to eq(6)
      expect(Capybara.default_max_wait_time).to eq(@previous_wait_time)
    end

    it 'should ensure wait time is reset' do
      expect do
        Capybara.using_wait_time 6 do
          raise 'hell'
        end
      end.to raise_error(RuntimeError, 'hell')
      expect(Capybara.default_max_wait_time).to eq(@previous_wait_time)
    end
  end
  # rubocop:enable RSpec/InstanceVariable

  describe '#app' do
    it 'should be changeable' do
      Capybara.app = 'foobar'
      expect(Capybara.app).to eq('foobar')
    end
  end

  describe '#current_session' do
    it 'should choose a session object of the current driver type' do
      expect(Capybara.current_session).to be_a(Capybara::Session)
    end

    it 'should use #app as the application' do
      Capybara.app = proc {}
      expect(Capybara.current_session.app).to eq(Capybara.app)
    end

    it 'should change with the current driver' do
      expect(Capybara.current_session.mode).to eq(:rack_test)
      Capybara.current_driver = :selenium
      expect(Capybara.current_session.mode).to eq(:selenium)
    end

    it 'should be persistent even across driver changes' do
      object_id = Capybara.current_session.object_id
      expect(Capybara.current_session.object_id).to eq(object_id)
      Capybara.current_driver = :selenium
      expect(Capybara.current_session.mode).to eq(:selenium)
      expect(Capybara.current_session.object_id).not_to eq(object_id)

      Capybara.current_driver = :rack_test
      expect(Capybara.current_session.object_id).to eq(object_id)
    end

    it 'should change when changing application' do
      object_id = Capybara.current_session.object_id
      expect(Capybara.current_session.object_id).to eq(object_id)
      Capybara.app = proc {}
      expect(Capybara.current_session.object_id).not_to eq(object_id)
      expect(Capybara.current_session.app).to eq(Capybara.app)
    end

    it 'should change when the session name changes' do
      object_id = Capybara.current_session.object_id
      Capybara.session_name = :administrator
      expect(Capybara.session_name).to eq(:administrator)
      expect(Capybara.current_session.object_id).not_to eq(object_id)
      Capybara.session_name = :default
      expect(Capybara.session_name).to eq(:default)
      expect(Capybara.current_session.object_id).to eq(object_id)
    end
  end

  describe '#using_session' do
    it 'should change the session name for the duration of the block' do
      expect(Capybara.session_name).to eq(:default)
      Capybara.using_session(:administrator) do
        expect(Capybara.session_name).to eq(:administrator)
      end
      expect(Capybara.session_name).to eq(:default)
    end

    it 'should reset the session to the default, even if an exception occurs' do
      begin
        Capybara.using_session(:raise) do
          raise
        end
      rescue Exception # rubocop:disable Lint/RescueException,Lint/SuppressedException
      end
      expect(Capybara.session_name).to eq(:default)
    end

    it 'should yield the passed block' do
      called = false
      Capybara.using_session(:administrator) { called = true }
      expect(called).to be(true)
    end

    it 'should be nestable' do
      Capybara.using_session(:outer) do
        expect(Capybara.session_name).to eq(:outer)
        Capybara.using_session(:inner) do
          expect(Capybara.session_name).to eq(:inner)
        end
        expect(Capybara.session_name).to eq(:outer)
      end
      expect(Capybara.session_name).to eq(:default)
    end

    it 'should allow a session object' do
      original_session = Capybara.current_session
      new_session = Capybara::Session.new(:rack_test, proc {})
      Capybara.using_session(new_session) do
        expect(Capybara.current_session).to eq(new_session)
      end
      expect(Capybara.current_session).to eq(original_session)
    end

    it 'should pass the new session if block accepts' do
      original_session = Capybara.current_session
      Capybara.using_session(:administrator) do |admin_session, prev_session|
        expect(admin_session).to be(Capybara.current_session)
        expect(prev_session).to be(original_session)
        expect(prev_session).not_to be(admin_session)
      end
    end
  end

  describe '#session_name' do
    it 'should default to :default' do
      expect(Capybara.session_name).to eq(:default)
    end
  end

  describe 'the DSL' do
    let(:session) { Class.new { include Capybara::DSL }.new }

    it 'should be possible to include it in another class' do
      session.visit('/with_html')
      session.click_link('ullamco')
      expect(session.body).to include('Another World')
    end

    it "should provide a 'page' shortcut for more expressive tests" do
      session.page.visit('/with_html')
      session.page.click_link('ullamco')
      expect(session.page.body).to include('Another World')
    end

    it "should provide an 'using_session' shortcut" do
      allow(Capybara).to receive(:using_session)
      session.using_session(:name)
      expect(Capybara).to have_received(:using_session).with(:name)
    end

    it "should provide a 'using_wait_time' shortcut" do
      allow(Capybara).to receive(:using_wait_time)
      session.using_wait_time(6)
      expect(Capybara).to have_received(:using_wait_time).with(6)
    end
  end
end
