require "rails_helper"

RSpec.describe ReadOnlyDatabaseService do
  before do
    described_class.reset_connection_pool!
  end

  after do
    described_class.reset_connection_pool!
  end

  describe ".available?" do
    it "returns true when READ_ONLY_DATABASE_URL is set" do
      stub_const("ENV", ENV.to_h.merge("READ_ONLY_DATABASE_URL" => "postgresql://localhost/read_only_db"))
      expect(described_class.available?).to be true
    end

    it "returns false when READ_ONLY_DATABASE_URL is not set" do
      stub_const("ENV", ENV.to_h.merge("READ_ONLY_DATABASE_URL" => nil))
      expect(described_class.available?).to be false
    end

    it "returns false when READ_ONLY_DATABASE_URL is empty" do
      stub_const("ENV", ENV.to_h.merge("READ_ONLY_DATABASE_URL" => ""))
      expect(described_class.available?).to be false
    end
  end

  describe ".connection_info" do
    it "returns nil when not available" do
      stub_const("ENV", ENV.to_h.merge("READ_ONLY_DATABASE_URL" => nil))
      expect(described_class.connection_info).to be_nil
    end

    it "returns parsed connection info when available" do
      test_url = "postgresql://testuser:secret@dbhost:5433/custom_db"
      stub_const("ENV", ENV.to_h.merge("READ_ONLY_DATABASE_URL" => test_url))
      expect(described_class.connection_info).to eq(
        host: "dbhost",
        port: 5433,
        database: "custom_db",
        username: "testuser",
      )
    end
  end

  describe ".with_connection" do
    context "when read-only database is not configured" do
      it "uses the main database connection pool" do
        stub_const("ENV", ENV.to_h.merge("READ_ONLY_DATABASE_URL" => nil))

        yielded_conn = nil
        described_class.with_connection do |conn|
          yielded_conn = conn
        end

        expect(yielded_conn).to be_a(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter)
      end
    end

    context "when read-only database is configured" do
      let(:mock_pool) { instance_spy(ActiveRecord::ConnectionAdapters::ConnectionPool) }
      let(:mock_conn) { instance_spy(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter) }

      before do
        stub_const("ENV", ENV.to_h.merge("READ_ONLY_DATABASE_URL" => "postgresql://localhost/read_only_db"))
        allow(described_class).to receive_messages(
          connection_pool: mock_pool,
          fetch_session_settings: nil,
          restore_session_settings: nil,
        )
      end

      it "yields the connection from the read-only pool" do
        allow(mock_pool).to receive(:with_connection).and_yield(mock_conn)

        yielded = nil
        described_class.with_connection do |conn|
          yielded = conn
        end

        expect(yielded).to eq(mock_conn)
        expect(mock_pool).to have_received(:with_connection)
      end

      it "falls back to main database on PG::ConnectionBad" do
        allow(mock_pool).to receive(:with_connection).and_raise(PG::ConnectionBad.new("could not connect to server"))
        allow(Rails.logger).to receive(:error)

        yielded_conn = nil
        described_class.with_connection do |conn|
          yielded_conn = conn
        end

        expect(yielded_conn).to be_a(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter)
        expect(Rails.logger).to have_received(:error).with(
          /Read-only database connection failed.*falling back to main database/,
        )
      end

      it "falls back to main database on ActiveRecord::ConnectionNotEstablished" do
        conn_error = ActiveRecord::ConnectionNotEstablished.new("No connection")
        allow(mock_pool).to receive(:with_connection).and_raise(conn_error)
        allow(Rails.logger).to receive(:error)

        yielded_conn = nil
        described_class.with_connection do |conn|
          yielded_conn = conn
        end

        expect(yielded_conn).to be_a(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter)
        expect(Rails.logger).to have_received(:error).with(
          /Read-only database connection failed.*falling back to main database/,
        )
      end
    end
  end

  describe ".health_check" do
    it "returns not_configured status when not configured" do
      stub_const("ENV", ENV.to_h.merge("READ_ONLY_DATABASE_URL" => nil))
      expect(described_class.health_check).to eq(
        status: "not_configured",
        message: "Read-only database not configured",
      )
    end

    it "returns healthy when connection succeeds" do
      stub_const("ENV", ENV.to_h.merge("READ_ONLY_DATABASE_URL" => "postgresql://localhost/read_only_db"))
      mock_conn = instance_spy(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter)
      allow(described_class).to receive(:with_connection).and_yield(mock_conn)
      allow(mock_conn).to receive(:execute).with("SELECT 1 as health_check")

      result = described_class.health_check
      expect(result[:status]).to eq("healthy")
      expect(result[:message]).to match(/successful/)
    end

    it "returns unhealthy when connection raises error" do
      stub_const("ENV", ENV.to_h.merge("READ_ONLY_DATABASE_URL" => "postgresql://localhost/read_only_db"))
      allow(described_class).to receive(:with_connection).and_raise(StandardError.new("connection error"))

      result = described_class.health_check
      expect(result[:status]).to eq("unhealthy")
      expect(result[:message]).to match(/connection error/)
    end
  end

  describe ".reset_connection_pool!" do
    it "disconnects existing pool and clears reference" do
      mock_pool = instance_spy(ActiveRecord::ConnectionAdapters::ConnectionPool)
      described_class.instance_variable_set(:@connection_pool, mock_pool)

      allow(mock_pool).to receive(:disconnect!)
      described_class.reset_connection_pool!
      expect(mock_pool).to have_received(:disconnect!)
      expect(described_class.instance_variable_get(:@connection_pool)).to be_nil
    end
  end
end
