require "rails_helper"
require Rails.root.join("db/migrate/20261119161300_validate_event_id_on_articles")

RSpec.describe ValidateEventIdOnArticles do
  subject(:migration) { described_class.new }

  let(:fake_pg_connection_class) do
    Class.new do
      attr_reader :exec_calls, :closed

      def initialize(exec_results: [])
        @exec_results = exec_results.dup
        @exec_calls = []
        @closed = false
      end

      def exec(sql)
        @exec_calls << sql
        @exec_results.shift || []
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

  it "validates an unvalidated foreign key over a direct unpooled zero-timeout connection" do
    constraint = [{ "qualified_table" => "public.articles",
                    "quoted_constraint" => "fk_rails_874457d35c",
                    "convalidated" => "f" }]
    fake_conn = fake_pg_connection_class.new(exec_results: [constraint, []])
    connect_params = nil
    allow(PG::Connection).to receive(:connect) do |params|
      connect_params = params
      fake_conn
    end

    migration.up

    expect(connect_params[:host]).to eq("db-primary.example.test")
    expect(connect_params).not_to have_key(:hostaddr)
    expect(connect_params[:options]).to eq("application_name=forem -c statement_timeout=0")
    expect(fake_conn.exec_calls.last).to eq("ALTER TABLE public.articles VALIDATE CONSTRAINT fk_rails_874457d35c;")
    expect(fake_conn.closed).to be(true)
  end

  it "skips validation when the foreign key is already validated" do
    constraint = [{ "qualified_table" => "public.articles",
                    "quoted_constraint" => "fk_rails_874457d35c",
                    "convalidated" => "t" }]
    fake_conn = fake_pg_connection_class.new(exec_results: [constraint])
    allow(PG::Connection).to receive(:connect).and_return(fake_conn)

    migration.up

    expect(fake_conn.exec_calls.length).to eq(1)
    expect(fake_conn.closed).to be(true)
  end

  it "raises ActiveRecord::MigrationError when the foreign key is missing" do
    fake_conn = fake_pg_connection_class.new(exec_results: [[]])
    allow(PG::Connection).to receive(:connect).and_return(fake_conn)

    expect { migration.up }.to raise_error(
      ActiveRecord::MigrationError,
      /Foreign key from articles\.event_id to events not found/,
    )
    expect(fake_conn.closed).to be(true)
  end

  it "wraps PG::Error from connection startup in ActiveRecord::MigrationError" do
    allow(PG::Connection).to receive(:connect).and_raise(PG::ConnectionBad, "could not connect")

    expect { migration.up }.to raise_error(
      ActiveRecord::MigrationError,
      /Could not open a direct zero-timeout session to validate articles\.event_id foreign key/,
    )
  end

  it "is a no-op on down" do
    allow(PG::Connection).to receive(:connect)

    expect { migration.down }.not_to raise_error
    expect(PG::Connection).not_to have_received(:connect)
  end
end
