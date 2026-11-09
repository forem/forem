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

    it "exposes remaining_timeout during the request and cleans up thread locals afterward" do
      observed_remaining = nil
      inner_app = lambda do |request_env|
        request_env[described_class::ENV_INFO_KEY].timeout = 4.5
        observed_remaining = RackTimeoutThreadTracker.remaining_timeout
        [200, {}, ["OK"]]
      end

      described_class.new(inner_app).call(env)

      expect(observed_remaining).to be_within(0.5).of(4.5)
      expect(RackTimeoutThreadTracker.remaining_timeout).to be_nil
      expect(Thread.current[:rack_timeout_env]).to be_nil
      expect(Thread.current[:rack_timeout_started_at]).to be_nil
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

      it "cancels in-flight query and closes the raw database connection socket for the tracked thread" do
        pool = ActiveRecord::Base.connection_pool
        mock_connection = double("ActiveRecord::ConnectionAdapters::PostgreSQLAdapter")
        mock_raw_connection = double("PG::Connection")
        mock_tcc = { mock_thread => mock_connection }

        # Mock the connection pool internals
        allow(pool).to receive(:instance_variable_get).with(:@thread_cached_conns).and_return(mock_tcc)
        allow(mock_connection).to receive(:raw_connection).and_return(mock_raw_connection)
        allow(mock_raw_connection).to receive(:respond_to?).with(:cancel).and_return(true)
        allow(mock_raw_connection).to receive(:cancel)
        allow(mock_raw_connection).to receive(:respond_to?).with(:close).and_return(true)
        allow(mock_raw_connection).to receive(:close)
        allow(mock_connection).to receive(:disconnect!)
        allow(pool).to receive(:release_connection)

        # Retrieve the observer proc directly from the registry
        observers = described_class.instance_variable_get(:@state_change_observers)
        observer_proc = observers[:clear_db_connections_on_timeout]
        expect(observer_proc).not_to be_nil

        observer_proc.call(env)

        expect(mock_raw_connection).to have_received(:cancel).ordered
        expect(mock_raw_connection).to have_received(:close).ordered
        expect(mock_connection).not_to have_received(:disconnect!)
        expect(pool).not_to have_received(:release_connection)
      end

      it "still closes the raw connection if cancel raises an exception" do
        pool = ActiveRecord::Base.connection_pool
        mock_connection = double("ActiveRecord::ConnectionAdapters::PostgreSQLAdapter")
        mock_raw_connection = double("PG::Connection")
        mock_tcc = { mock_thread => mock_connection }

        allow(pool).to receive(:instance_variable_get).with(:@thread_cached_conns).and_return(mock_tcc)
        allow(mock_connection).to receive(:raw_connection).and_return(mock_raw_connection)
        allow(mock_raw_connection).to receive(:respond_to?).with(:cancel).and_return(true)
        allow(mock_raw_connection).to receive(:cancel).and_raise(StandardError.new("cancel error"))
        allow(mock_raw_connection).to receive(:respond_to?).with(:close).and_return(true)
        allow(mock_raw_connection).to receive(:close)

        observers = described_class.instance_variable_get(:@state_change_observers)
        observer_proc = observers[:clear_db_connections_on_timeout]

        expect { observer_proc.call(env) }.not_to raise_error
        expect(mock_raw_connection).to have_received(:close)
      end

      it "falls back to calling finish if the raw connection does not respond to close but responds to finish" do
        pool = ActiveRecord::Base.connection_pool
        mock_connection = double("ActiveRecord::ConnectionAdapters::PostgreSQLAdapter")
        mock_raw_connection = double("PG::Connection")
        mock_tcc = { mock_thread => mock_connection }

        # Mock the connection pool internals
        allow(pool).to receive(:instance_variable_get).with(:@thread_cached_conns).and_return(mock_tcc)
        allow(mock_connection).to receive(:raw_connection).and_return(mock_raw_connection)
        allow(mock_raw_connection).to receive(:respond_to?).with(:cancel).and_return(false)
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
        allow(mock_raw_connection).to receive(:respond_to?).with(:cancel).and_return(false)
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

      it "locates the tracked thread's connection via Rails 8 @leases and marks the adapter unverified" do
        pool = ActiveRecord::Base.connection_pool
        mock_connection = instance_double(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter)
        mock_raw_connection = instance_double(PG::Connection, cancel: nil, close: nil)
        lease_class = Struct.new(:connection)
        mock_leases = { mock_thread => lease_class.new(mock_connection) }

        allow(pool).to receive(:instance_variable_get).with(:@thread_cached_conns).and_return(nil)
        allow(pool).to receive(:instance_variable_get).with(:@leases).and_return(mock_leases)
        allow(mock_connection).to receive(:raw_connection).and_return(mock_raw_connection)

        observers = described_class.instance_variable_get(:@state_change_observers)
        observers[:clear_db_connections_on_timeout].call(env)

        expect(mock_raw_connection).to have_received(:cancel).ordered
        expect(mock_raw_connection).to have_received(:close).ordered
        expect(mock_connection.instance_variable_get(:@verified)).to be(false)
        expect(mock_connection.instance_variable_get(:@last_activity)).to be_nil
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

  describe "ActiveRecord::StatementCache retryability" do
    it "defaults allow_retry to true when executing cached association statements" do
      article = create(:article)
      create(:discussion_lock, article: article)
      article.reload
      allow(DiscussionLock).to receive(:find_by_sql).and_call_original

      expect(article.discussion_lock).to be_present
      expect(DiscussionLock).to have_received(:find_by_sql)
        .with(anything, anything, hash_including(preparable: true, allow_retry: true))
    end
  end
end
# rubocop:enable RSpec/FilePath, RSpec/SpecFilePathFormat
