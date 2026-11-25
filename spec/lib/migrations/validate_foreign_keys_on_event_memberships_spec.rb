require "rails_helper"
require Rails.root.join("db/migrate/20261125150200_validate_foreign_keys_on_event_memberships")

RSpec.describe ValidateForeignKeysOnEventMemberships do
  subject(:migration) { described_class.new }

  let(:fake_pg_connection_class) do
    Class.new do
      attr_reader :exec_calls, :exec_params_calls, :closed

      def initialize(exec_results: [], exec_params_results: [])
        @exec_results = exec_results.dup
        @exec_params_results = exec_params_results.dup
        @exec_calls = []
        @exec_params_calls = []
        @closed = false
      end

      def exec(sql)
        @exec_calls << sql
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

  it "validates both unvalidated foreign keys over a direct unpooled zero-timeout connection" do
    parent_fk = [{ "qualified_table" => "public.event_memberships",
                   "quoted_constraint" => "fk_rails_parent",
                   "convalidated" => "f" }]
    child_fk = [{ "qualified_table" => "public.event_memberships",
                  "quoted_constraint" => "fk_rails_child",
                  "convalidated" => "f" }]
    fake_conn = fake_pg_connection_class.new(exec_params_results: [parent_fk, child_fk])
    connect_params = nil
    allow(PG::Connection).to receive(:connect) do |params|
      connect_params = params
      fake_conn
    end

    migration.up

    expect(connect_params[:host]).to eq("db-primary.example.test")
    expect(connect_params).not_to have_key(:hostaddr)
    expect(connect_params[:options]).to eq("application_name=forem -c statement_timeout=0")
    expect(fake_conn.exec_calls).to eq([
                                         "ALTER TABLE public.event_memberships VALIDATE CONSTRAINT fk_rails_parent;",
                                         "ALTER TABLE public.event_memberships VALIDATE CONSTRAINT fk_rails_child;",
                                       ])
    expect(fake_conn.closed).to be(true)
  end

  it "skips already-validated foreign keys" do
    parent_fk = [{ "qualified_table" => "public.event_memberships",
                   "quoted_constraint" => "fk_rails_parent",
                   "convalidated" => "t" }]
    child_fk = [{ "qualified_table" => "public.event_memberships",
                  "quoted_constraint" => "fk_rails_child",
                  "convalidated" => "t" }]
    fake_conn = fake_pg_connection_class.new(exec_params_results: [parent_fk, child_fk])
    allow(PG::Connection).to receive(:connect).and_return(fake_conn)

    migration.up

    expect(fake_conn.exec_calls).to be_empty
    expect(fake_conn.closed).to be(true)
  end

  it "raises ActiveRecord::MigrationError when a foreign key is missing" do
    fake_conn = fake_pg_connection_class.new(exec_params_results: [[]])
    allow(PG::Connection).to receive(:connect).and_return(fake_conn)

    expect { migration.up }.to raise_error(
      ActiveRecord::MigrationError,
      /Foreign key from event_memberships\.parent_event_id to events not found/,
    )
    expect(fake_conn.closed).to be(true)
  end

  it "wraps PG::Error from connection startup in ActiveRecord::MigrationError" do
    allow(PG::Connection).to receive(:connect).and_raise(PG::ConnectionBad, "could not connect")

    expect { migration.up }.to raise_error(
      ActiveRecord::MigrationError,
      /Could not open a direct zero-timeout session to validate event_memberships foreign keys/,
    )
  end

  it "is a no-op on down" do
    allow(PG::Connection).to receive(:connect)

    expect { migration.down }.not_to raise_error
    expect(PG::Connection).not_to have_received(:connect)
  end
end
