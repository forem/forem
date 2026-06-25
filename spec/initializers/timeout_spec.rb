# rubocop:disable RSpec/FilePath, RSpec/SpecFilePathFormat
require "rails_helper"

RSpec.describe Rack::Timeout, type: :initializer do
  describe "RackTimeoutThreadTracker prepended module" do
    let(:app) { double("app", call: nil) }
    let(:middleware) { described_class.new(app) }
    let(:env) { {} }

    it "records the current thread as rack-timeout.request_thread" do
      middleware.call(env)
      expect(env["rack-timeout.request_thread"]).to eq(Thread.current)
    end
  end

  describe "clear_db_connections_on_timeout state change observer" do
    let(:env) { {} }
    let(:state_info) { instance_double(described_class::RequestDetails, state: state) }

    before do
      env[described_class::ENV_INFO_KEY] = state_info
    end

    context "when state is :timed_out" do
      let(:state) { :timed_out }
      let(:mock_thread) { instance_double(Thread) }

      before do
        env["rack-timeout.request_thread"] = mock_thread
      end

      it "closes the raw database connection socket for the tracked thread" do
        pool = ActiveRecord::Base.connection_pool
        mock_connection = double("ActiveRecord::ConnectionAdapters::PostgreSQLAdapter")
        mock_raw_connection = double("PG::Connection")
        mock_tcc = { mock_thread => mock_connection }

        # Mock the connection pool internals
        allow(pool).to receive(:instance_variable_get).with(:@thread_cached_conns).and_return(mock_tcc)
        allow(mock_connection).to receive(:raw_connection).and_return(mock_raw_connection)
        allow(mock_raw_connection).to receive(:respond_to?).with(:close).and_return(true)
        allow(mock_raw_connection).to receive(:close)
        allow(mock_connection).to receive(:disconnect!)
        allow(pool).to receive(:release_connection)

        # Retrieve the observer proc directly from the registry
        observers = described_class.instance_variable_get(:@state_change_observers)
        observer_proc = observers[:clear_db_connections_on_timeout]
        expect(observer_proc).not_to be_nil

        observer_proc.call(env)

        expect(mock_raw_connection).to have_received(:close)
        expect(mock_connection).not_to have_received(:disconnect!)
        expect(pool).not_to have_received(:release_connection)
      end

      it "falls back to calling finish if the raw connection does not respond to close but responds to finish" do
        pool = ActiveRecord::Base.connection_pool
        mock_connection = double("ActiveRecord::ConnectionAdapters::PostgreSQLAdapter")
        mock_raw_connection = double("PG::Connection")
        mock_tcc = { mock_thread => mock_connection }

        # Mock the connection pool internals
        allow(pool).to receive(:instance_variable_get).with(:@thread_cached_conns).and_return(mock_tcc)
        allow(mock_connection).to receive(:raw_connection).and_return(mock_raw_connection)
        allow(mock_raw_connection).to receive(:respond_to?).with(:close).and_return(false)
        allow(mock_raw_connection).to receive(:respond_to?).with(:finish).and_return(true)
        allow(mock_raw_connection).to receive(:finish)
        allow(mock_connection).to receive(:disconnect!)
        allow(pool).to receive(:release_connection)

        # Retrieve the observer proc directly from the registry
        observers = described_class.instance_variable_get(:@state_change_observers)
        observer_proc = observers[:clear_db_connections_on_timeout]
        expect(observer_proc).not_to be_nil

        observer_proc.call(env)

        expect(mock_raw_connection).to have_received(:finish)
        expect(mock_connection).not_to have_received(:disconnect!)
        expect(pool).not_to have_received(:release_connection)
      end

      it "rescues errors if closing the raw connection raises an exception" do
        pool = ActiveRecord::Base.connection_pool
        mock_connection = double("ActiveRecord::ConnectionAdapters::PostgreSQLAdapter")
        mock_raw_connection = double("PG::Connection")
        mock_tcc = { mock_thread => mock_connection }

        # Mock the connection pool internals
        allow(pool).to receive(:instance_variable_get).with(:@thread_cached_conns).and_return(mock_tcc)
        allow(mock_connection).to receive(:raw_connection).and_return(mock_raw_connection)
        allow(mock_raw_connection).to receive(:respond_to?).with(:close).and_return(true)
        allow(mock_raw_connection).to receive(:close).and_raise(StandardError.new("close error"))
        allow(mock_connection).to receive(:disconnect!)
        allow(pool).to receive(:release_connection)

        # Retrieve the observer proc directly from the registry
        observers = described_class.instance_variable_get(:@state_change_observers)
        observer_proc = observers[:clear_db_connections_on_timeout]
        expect(observer_proc).not_to be_nil

        # Verify it rescues the error and does not raise
        expect { observer_proc.call(env) }.not_to raise_error

        expect(mock_raw_connection).to have_received(:close)
        expect(mock_connection).not_to have_received(:disconnect!)
        expect(pool).not_to have_received(:release_connection)
      end
    end

    context "when state is other than timed_out" do
      let(:state) { :ready }

      it "does not clear connections" do
        pool = ActiveRecord::Base.connection_pool
        allow(pool).to receive(:instance_variable_get)
        allow(pool).to receive(:release_connection)

        observers = described_class.instance_variable_get(:@state_change_observers)
        observer_proc = observers[:clear_db_connections_on_timeout]
        expect(observer_proc).not_to be_nil

        observer_proc.call(env)

        expect(pool).not_to have_received(:instance_variable_get)
        expect(pool).not_to have_received(:release_connection)
      end
    end
  end
end
# rubocop:enable RSpec/FilePath, RSpec/SpecFilePathFormat
