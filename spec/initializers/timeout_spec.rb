# rubocop:disable RSpec/FilePath, RSpec/SpecFilePathFormat
require "rails_helper"

RSpec.describe Rack::Timeout, type: :initializer do
  describe "RackTimeoutThreadTracker prepended module" do
    let(:app) { ->(_env) { [200, {}, ["OK"]] } }
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

      it "cancels the in-flight query via @raw_connection and taints the adapter without closing cross-thread" do
        pool = ActiveRecord::Base.connection_pool
        mock_raw_connection = instance_double(PG::Connection, finished?: false, cancel: nil, close: nil, finish: nil)
        mock_connection = instance_double(
          ActiveRecord::ConnectionAdapters::PostgreSQLAdapter,
          raw_connection: mock_raw_connection,
          disconnect!: nil,
        )
        mock_connection.instance_variable_set(:@raw_connection, mock_raw_connection)
        mock_connection.instance_variable_set(:@verified, true)
        mock_connection.instance_variable_set(:@last_activity, 123.45)

        lease_class = Struct.new(:connection)
        mock_leases = { mock_thread => lease_class.new(mock_connection) }

        allow(pool).to receive(:instance_variable_get).and_call_original
        allow(pool).to receive(:instance_variable_get).with(:@thread_cached_conns).and_return(nil)
        allow(pool).to receive(:instance_variable_get).with(:@leases).and_return(mock_leases)
        allow(pool).to receive(:release_connection)

        observers = described_class.instance_variable_get(:@state_change_observers)
        observer_proc = observers[:clear_db_connections_on_timeout]
        expect(observer_proc).not_to be_nil

        observer_proc.call(env)

        expect(mock_connection).not_to have_received(:raw_connection)
        expect(mock_raw_connection).to have_received(:cancel)
        expect(mock_raw_connection).not_to have_received(:close)
        expect(mock_raw_connection).not_to have_received(:finish)
        expect(mock_connection).not_to have_received(:disconnect!)
        expect(pool).not_to have_received(:release_connection)
        expect(mock_connection.instance_variable_get(:@rack_timeout_tainted)).to be(true)
      end

      it "marks the timed-out adapter unverified and clears @last_activity" do
        pool = ActiveRecord::Base.connection_pool
        mock_raw_connection = instance_double(PG::Connection, finished?: false, cancel: nil)
        mock_connection = instance_double(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter)
        mock_connection.instance_variable_set(:@raw_connection, mock_raw_connection)
        mock_connection.instance_variable_set(:@verified, true)
        mock_connection.instance_variable_set(:@last_activity, 123.45)

        lease_class = Struct.new(:connection)
        mock_leases = { mock_thread => lease_class.new(mock_connection) }

        allow(pool).to receive(:instance_variable_get).and_call_original
        allow(pool).to receive(:instance_variable_get).with(:@thread_cached_conns).and_return(nil)
        allow(pool).to receive(:instance_variable_get).with(:@leases).and_return(mock_leases)

        observers = described_class.instance_variable_get(:@state_change_observers)
        observers[:clear_db_connections_on_timeout].call(env)

        expect(mock_connection.instance_variable_get(:@verified)).to be(false)
        expect(mock_connection.instance_variable_get(:@last_activity)).to be_nil
      end

      it "skips cancel when @raw_connection is nil or already finished" do
        pool = ActiveRecord::Base.connection_pool
        mock_raw_connection = instance_double(PG::Connection, finished?: true, cancel: nil)
        mock_connection = instance_double(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter)
        mock_connection.instance_variable_set(:@raw_connection, mock_raw_connection)

        lease_class = Struct.new(:connection)
        mock_leases = { mock_thread => lease_class.new(mock_connection) }

        allow(pool).to receive(:instance_variable_get).and_call_original
        allow(pool).to receive(:instance_variable_get).with(:@thread_cached_conns).and_return(nil)
        allow(pool).to receive(:instance_variable_get).with(:@leases).and_return(mock_leases)

        observers = described_class.instance_variable_get(:@state_change_observers)
        observers[:clear_db_connections_on_timeout].call(env)

        expect(mock_raw_connection).not_to have_received(:cancel)
        expect(mock_connection.instance_variable_get(:@rack_timeout_tainted)).to be(true)
      end

      it "rescues and logs errors if cancel raises an exception" do
        pool = ActiveRecord::Base.connection_pool
        mock_raw_connection = instance_double(PG::Connection, finished?: false)
        mock_connection = instance_double(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter)
        mock_connection.instance_variable_set(:@raw_connection, mock_raw_connection)

        lease_class = Struct.new(:connection)
        mock_leases = { mock_thread => lease_class.new(mock_connection) }

        allow(pool).to receive(:instance_variable_get).and_call_original
        allow(pool).to receive(:instance_variable_get).with(:@thread_cached_conns).and_return(nil)
        allow(pool).to receive(:instance_variable_get).with(:@leases).and_return(mock_leases)
        allow(mock_raw_connection).to receive(:cancel).and_raise(StandardError.new("cancel error"))

        observers = described_class.instance_variable_get(:@state_change_observers)
        observer_proc = observers[:clear_db_connections_on_timeout]

        expect { observer_proc.call(env) }.not_to raise_error
        expect(mock_connection.instance_variable_get(:@rack_timeout_tainted)).to be(true)
        expect(mock_connection.instance_variable_get(:@verified)).to be(false)
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

  describe "ConnectionPool checkin cleanup and closed PG::Connection auto-reconnect" do
    let(:isolated_pool) do
      ActiveRecord::ConnectionAdapters::ConnectionPool.new(ActiveRecord::Base.connection_pool.pool_config)
    end

    after do
      isolated_pool.disconnect!
    end

    it "disconnects tainted adapters on checkin so subsequent retryable queries reconnect cleanly" do
      captured_conn = nil
      captured_raw = nil

      expect do
        isolated_pool.with_connection do |conn|
          conn.execute("SELECT 1")
          captured_conn = conn
          captured_raw = conn.instance_variable_get(:@raw_connection)
          RackTimeoutThreadTracker.cancel_and_taint_connection(conn)
          raise Rack::Timeout::RequestTimeoutError.new({}), "timed out"
        end
      end.to raise_error(Rack::Timeout::RequestTimeoutError)

      expect(captured_raw.finished?).to be(true)
      expect(captured_conn.instance_variable_get(:@raw_connection)).to be_nil
      expect(captured_conn.instance_variable_get(:@rack_timeout_tainted)).to be(false)

      isolated_pool.with_connection do |conn|
        expect(conn).to equal(captured_conn)
        result = conn.select_all(User.where(username: "nonexistent_timeout_spec_user").arel, "User Load")
        expect(result.to_a).to eq([])
        expect(conn.instance_variable_get(:@raw_connection)).not_to be_nil
        expect(conn.instance_variable_get(:@raw_connection).finished?).to be(false)
      end
    end

    it "reconnects instead of raising PG::ConnectionBad when @raw_connection is already closed" do
      captured_conn = nil
      isolated_pool.with_connection do |conn|
        conn.execute("SELECT 1")
        captured_conn = conn
      end

      raw_conn = captured_conn.instance_variable_get(:@raw_connection)
      raw_conn.close
      captured_conn.instance_variable_set(:@verified, false)
      captured_conn.instance_variable_set(:@last_activity, nil)
      expect(raw_conn.finished?).to be(true)

      isolated_pool.with_connection do |conn|
        expect(conn).to equal(captured_conn)
        result = conn.select_all(Article.where(path: "/nonexistent/timeout-spec-slug").arel, "Article Load")
        expect(result.to_a).to eq([])
        expect(conn.instance_variable_get(:@raw_connection).finished?).to be(false)
      end
    end

    it "aborts an in-flight cross-thread query cleanly without poisoning the pool for subsequent requests" do
      ready = Queue.new
      request_thread = Thread.new do
        isolated_pool.with_connection do |conn|
          conn.execute("SELECT 1")
          ready << conn
          conn.execute("SELECT pg_sleep(5)")
        end
      rescue ActiveRecord::QueryCanceled => e
        e
      end

      timed_out_conn = ready.pop
      raw_conn = timed_out_conn.instance_variable_get(:@raw_connection)
      deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 2.0
      while raw_conn.transaction_status != PG::PQTRANS_ACTIVE &&
          Process.clock_gettime(Process::CLOCK_MONOTONIC) < deadline
        Thread.pass
      end

      RackTimeoutThreadTracker.cancel_and_taint_connection(timed_out_conn)
      expect(request_thread.join(2)).to eq(request_thread)
      expect(request_thread.value).to be_a(ActiveRecord::QueryCanceled)

      isolated_pool.with_connection do |conn|
        expect(conn).to equal(timed_out_conn)
        result = conn.select_all(Article.where(path: "/nonexistent/concurrent-timeout-slug").arel, "Article Load")
        expect(result.to_a).to eq([])
      end
    end

    it "unwinds timed-out transactions and savepoints without blocking on ROLLBACK when cancel is ignored" do
      ready = Queue.new
      started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      request_thread = Thread.new do
        isolated_pool.with_connection do |conn|
          conn.transaction do
            conn.execute("SELECT 1")
            conn.transaction(requires_new: true) do
              conn.execute("SELECT 1")
              raw = conn.instance_variable_get(:@raw_connection)
              allow(raw).to receive(:cancel).and_return(nil)
              ready << conn
              conn.execute("SELECT pg_sleep(5)")
            end
          end
        end
      rescue Rack::Timeout::RequestTimeoutException => e
        e
      end

      timed_out_conn = ready.pop
      raw_conn = timed_out_conn.instance_variable_get(:@raw_connection)
      deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 2.0
      while raw_conn.transaction_status != PG::PQTRANS_ACTIVE &&
          Process.clock_gettime(Process::CLOCK_MONOTONIC) < deadline
        Thread.pass
      end

      RackTimeoutThreadTracker.cancel_and_taint_connection(timed_out_conn)
      request_thread.raise(Rack::Timeout::RequestTimeoutException.new({}), "timed out")
      expect(request_thread.join(1.5)).to eq(request_thread)
      expect(request_thread.value).to be_a(Rack::Timeout::RequestTimeoutException)
      expect(Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at).to be < 1.5

      isolated_pool.with_connection do |conn|
        expect(conn).to equal(timed_out_conn)
        expect(conn.open_transactions).to eq(0)
        expect(conn.select_value("SELECT 1")).to eq(1)
      end
    end

    it "clears the taint flag if the adapter reconnects before checkin" do
      isolated_pool.with_connection do |conn|
        conn.execute("SELECT 1")
        RackTimeoutThreadTracker.cancel_and_taint_connection(conn)
        expect(conn.active?).to be(false)

        expect(conn.select_value("SELECT 1")).to eq(1)
        expect(conn.instance_variable_get(:@rack_timeout_tainted)).to be(false)
        expect(conn.active?).to be(true)
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
