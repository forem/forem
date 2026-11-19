require "rails_helper"
require Rails.root.join("db/migrate/20261119161200_add_event_id_index_to_articles")

RSpec.describe AddEventIdIndexToArticles do
  subject(:migration) { described_class.new }

  let(:index_name) { described_class::INDEX_NAME }
  let(:qualified_index_name) { "public.#{index_name}" }
  let(:expected_drop_sql) { "DROP INDEX CONCURRENTLY IF EXISTS #{qualified_index_name};" }
  let(:expected_create_sql) do
    "CREATE INDEX CONCURRENTLY #{index_name} " \
      "ON articles (event_id, published, hotness_score DESC, published_at DESC) " \
      "WHERE (event_id IS NOT NULL);"
  end

  let(:fake_pg_connection_class) do
    Class.new do
      attr_reader :exec_calls, :exec_params_calls, :closed

      def initialize(exec_results: [], exec_params_results: [], raise_on_exec: nil)
        @exec_results = exec_results.dup
        @exec_params_results = exec_params_results.dup
        @raise_on_exec = raise_on_exec
        @exec_calls = []
        @exec_params_calls = []
        @closed = false
      end

      def exec(sql)
        @exec_calls << sql
        raise @raise_on_exec if @raise_on_exec && @exec_calls.length == 1

        @exec_results.shift || []
      end

      def exec_params(sql, params)
        @exec_params_calls << [sql, params]
        @exec_params_results.shift || []
      end

      def close
        @closed = true
      end
    end
  end

  let(:pooler_conninfo) do
    {
      host: "db-primary-pooler.example.test",
      hostaddr: "198.51.100.10",
      port: "5432",
      dbname: "forem_test",
      user: "postgres",
      sslmode: "require",
      options: "application_name=forem"
    }
  end

  before do
    allow(ActiveRecord::Base.connection.raw_connection).to receive(:conninfo_hash).and_return(pooler_conninfo)
  end

  it "disables DDL transactions" do
    expect(described_class.disable_ddl_transaction).to be(true)
  end

  it "opens a direct unpooled zero-timeout connection and creates the index when absent" do
    fake_conn = fake_pg_connection_class.new(exec_params_results: [[]])
    connect_params = nil
    allow(PG::Connection).to receive(:connect) do |params|
      connect_params = params
      fake_conn
    end

    migration.up

    expect(connect_params[:host]).to eq("db-primary.example.test")
    expect(connect_params).not_to have_key(:hostaddr)
    expect(connect_params[:options]).to eq("application_name=forem -c statement_timeout=0")
    expect(fake_conn.exec_calls).to eq([expected_create_sql])
    expect(fake_conn.closed).to be(true)
  end

  it "skips dropping and creating when a valid matching index already exists" do
    existing = [{ "qualified_name" => qualified_index_name, "usable" => "t" }]
    fake_conn = fake_pg_connection_class.new(exec_params_results: [existing])
    allow(PG::Connection).to receive(:connect).and_return(fake_conn)

    migration.up

    expect(fake_conn.exec_calls).to be_empty
    expect(fake_conn.closed).to be(true)
  end

  it "drops a leftover invalid or mismatched index concurrently before recreating" do
    existing = [{ "qualified_name" => qualified_index_name, "usable" => "f" }]
    fake_conn = fake_pg_connection_class.new(exec_params_results: [existing])
    allow(PG::Connection).to receive(:connect).and_return(fake_conn)

    migration.up

    expect(fake_conn.exec_calls).to eq([expected_drop_sql, expected_create_sql])
    expect(fake_conn.closed).to be(true)
  end

  it "drops the index concurrently on down when present and closes the connection" do
    existing = [{ "qualified_name" => qualified_index_name, "usable" => "t" }]
    fake_conn = fake_pg_connection_class.new(exec_params_results: [existing])
    allow(PG::Connection).to receive(:connect).and_return(fake_conn)

    migration.down

    expect(fake_conn.exec_calls).to eq([expected_drop_sql])
    expect(fake_conn.closed).to be(true)
  end

  it "closes the connection even if DDL execution fails" do
    fake_conn = fake_pg_connection_class.new(
      exec_params_results: [[]],
      raise_on_exec: PG::Error.new("boom"),
    )
    allow(PG::Connection).to receive(:connect).and_return(fake_conn)

    expect { migration.up }.to raise_error(PG::Error, "boom")
    expect(fake_conn.closed).to be(true)
  end

  it "wraps PG::Error from connection startup in ActiveRecord::MigrationError" do
    allow(PG::Connection).to receive(:connect).and_raise(PG::ConnectionBad, "could not connect")

    expect { migration.up }.to raise_error(
      ActiveRecord::MigrationError,
      /Could not open a direct zero-timeout session for #{Regexp.escape(index_name)}/,
    )
  end
end
