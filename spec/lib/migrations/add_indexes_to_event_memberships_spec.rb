require "rails_helper"
require Rails.root.join("db/migrate/20261125150100_add_indexes_to_event_memberships")

RSpec.describe AddIndexesToEventMemberships do
  subject(:migration) { described_class.new }

  let(:expected_create_sqls) { described_class::INDEXES.pluck(:create_sql) }

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

  it "opens a direct unpooled zero-timeout connection and creates all three indexes when absent" do
    fake_conn = fake_pg_connection_class.new(exec_params_results: [[], [], []])
    connect_params = nil
    allow(PG::Connection).to receive(:connect) do |params|
      connect_params = params
      fake_conn
    end

    migration.up

    expect(connect_params[:host]).to eq("db-primary.example.test")
    expect(connect_params).not_to have_key(:hostaddr)
    expect(connect_params[:options]).to eq("application_name=forem -c statement_timeout=0")
    expect(fake_conn.exec_calls).to eq(expected_create_sqls)
    expect(fake_conn.closed).to be(true)
  end

  it "skips dropping and creating when all valid matching indexes already exist" do
    existing = described_class::INDEXES.map do |spec|
      [{ "qualified_name" => "public.#{spec[:name]}", "usable" => "t" }]
    end
    fake_conn = fake_pg_connection_class.new(exec_params_results: existing)
    allow(PG::Connection).to receive(:connect).and_return(fake_conn)

    migration.up

    expect(fake_conn.exec_calls).to be_empty
    expect(fake_conn.closed).to be(true)
  end

  it "drops a leftover invalid index concurrently before recreating and keeps valid ones" do
    first_spec, second_spec, third_spec = described_class::INDEXES
    fake_conn = fake_pg_connection_class.new(
      exec_params_results: [
        [{ "qualified_name" => "public.#{first_spec[:name]}", "usable" => "f" }],
        [{ "qualified_name" => "public.#{second_spec[:name]}", "usable" => "t" }],
        [],
      ],
    )
    allow(PG::Connection).to receive(:connect).and_return(fake_conn)

    migration.up

    expect(fake_conn.exec_calls).to eq([
                                         "DROP INDEX CONCURRENTLY IF EXISTS public.#{first_spec[:name]};",
                                         first_spec[:create_sql],
                                         third_spec[:create_sql],
                                       ])
    expect(fake_conn.closed).to be(true)
  end

  it "drops existing indexes concurrently in reverse order on down and closes the connection" do
    existing = described_class::INDEXES.reverse.map do |spec|
      [{ "qualified_name" => "public.#{spec[:name]}", "usable" => "t" }]
    end
    fake_conn = fake_pg_connection_class.new(exec_params_results: existing)
    allow(PG::Connection).to receive(:connect).and_return(fake_conn)

    migration.down

    expected_drops = described_class::INDEXES.reverse.map do |spec|
      "DROP INDEX CONCURRENTLY IF EXISTS public.#{spec[:name]};"
    end
    expect(fake_conn.exec_calls).to eq(expected_drops)
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
      /Could not open a direct zero-timeout session for event_memberships indexes/,
    )
  end
end
