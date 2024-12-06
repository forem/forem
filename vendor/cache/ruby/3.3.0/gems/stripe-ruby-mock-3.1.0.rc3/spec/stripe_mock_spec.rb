require 'spec_helper'

describe StripeMock do

  it "overrides stripe's request method" do
    StripeMock.start
    Stripe::StripeClient.active_client.execute_request(:xtest, '/', api_key: 'abcde') # no error
    StripeMock.stop
  end

  it "overrides stripe's execute_request method in other threads" do
    StripeMock.start
    Thread.new { Stripe::StripeClient.active_client.execute_request(:xtest, '/', api_key: 'abcde') }.join # no error
    StripeMock.stop
  end

  it "reverts overriding stripe's request method" do
    StripeMock.start
    Stripe::StripeClient.active_client.execute_request(:xtest, '/', api_key: 'abcde') # no error
    StripeMock.stop
    expect { Stripe::StripeClient.active_client.execute_request(:x, '/', api_key: 'abcde') }.to raise_error Stripe::APIError
  end

  it "reverts overriding stripe's execute_request method in other threads" do
    StripeMock.start
    Thread.new { Stripe::StripeClient.active_client.execute_request(:xtest, '/', api_key: 'abcde') }.join # no error
    StripeMock.stop
    expect { Thread.new { Stripe::StripeClient.active_client.execute_request(:x, '/', api_key: 'abcde') }.join }.to raise_error Stripe::APIError
  end

  it "does not persist data between mock sessions" do
    StripeMock.start
    StripeMock.instance.customers[:x] = 9

    StripeMock.stop
    StripeMock.start

    expect(StripeMock.instance.customers[''][:x]).to be_nil
    expect(StripeMock.instance.customers[''].keys.length).to eq(0)
    StripeMock.stop
  end

  it "throws an error when trying to prepare an error before starting" do
    expect { StripeMock.prepare_error(StandardError.new) }.to raise_error {|e|
      expect(e).to be_a(StripeMock::UnstartedStateError)
    }

    expect { StripeMock.prepare_card_error(:card_declined) }.to raise_error {|e|
      expect(e).to be_a(StripeMock::UnstartedStateError)
    }
  end

  describe "Live Testing" do
    after { StripeMock.instance_variable_set(:@state, 'ready') }

    it "sets the default test strategy" do
      StripeMock.toggle_live(true)
      expect(StripeMock.create_test_helper).to be_a StripeMock::TestStrategies::Live

      StripeMock.toggle_live(false)
      expect(StripeMock.create_test_helper).to be_a StripeMock::TestStrategies::Mock
    end

    it "does not start when live" do
      expect(StripeMock.state).to eq 'ready'
      StripeMock.toggle_live(true)
      expect(StripeMock.state).to eq 'live'
      expect(StripeMock.start).to eq false
      expect(StripeMock.start_client).to eq false
    end

    it "can be undone" do
      StripeMock.toggle_live(true)
      StripeMock.toggle_live(false)
      expect(StripeMock.state).to eq 'ready'
      expect(StripeMock.start).to_not eq false
      StripeMock.stop
    end

    it "cannot be toggled when already started" do
      StripeMock.start
      expect { StripeMock.toggle_live(true) }.to raise_error
      StripeMock.stop

      StripeMock.instance_variable_set(:@state, 'remote')
      expect { StripeMock.toggle_live(true) }.to raise_error
    end
  end

  describe "Test Helper Strategies" do
    before { StripeMock.instance_variable_set("@__test_strat", nil) }

    it "uses mock by default" do
      helper = StripeMock.create_test_helper
      expect(helper).to be_a StripeMock::TestStrategies::Mock
    end

    it "can specify which strategy to use" do
      helper = StripeMock.create_test_helper(:live)
      expect(helper).to be_a StripeMock::TestStrategies::Live

      helper = StripeMock.create_test_helper(:mock)
      expect(helper).to be_a StripeMock::TestStrategies::Mock
    end

    it "throws an error on an unknown strategy" do
      expect { StripeMock.create_test_helper(:lol) }.to raise_error
    end

    it "can configure the default strategy" do
      StripeMock.set_default_test_helper_strategy(:live)
      helper = StripeMock.create_test_helper
      expect(helper).to be_a StripeMock::TestStrategies::Live
    end

    it "can overrige a set default strategy" do
      StripeMock.set_default_test_helper_strategy(:live)
      helper = StripeMock.create_test_helper(:mock)
      expect(helper).to be_a StripeMock::TestStrategies::Mock
    end
  end

end
