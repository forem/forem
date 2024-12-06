require 'unit_spec_helper'
require 'rpush/daemon/store/active_record/reconnectable'

describe Rpush::Daemon::Store::ActiveRecord::Reconnectable do
  class TestDouble
    include Rpush::Daemon::Store::ActiveRecord::Reconnectable

    attr_reader :name

    def initialize(error, max_calls)
      @error = error
      @max_calls = max_calls
      @calls = 0
    end

    def perform
      with_database_reconnect_and_retry do
        @calls += 1
        fail @error if @calls <= @max_calls
      end
    end
  end

  let(:adapter_error_class) do
    case SPEC_ADAPTER
    when 'postgresql'
      PGError
    when 'mysql'
      Mysql::Error
    when 'mysql2'
      Mysql2::Error
    when 'jdbcpostgresql'
      ActiveRecord::JDBCError
    when 'jdbcmysql'
      ActiveRecord::JDBCError
    when 'jdbch2'
      ActiveRecord::JDBCError
    when 'sqlite3'
      SQLite3::Exception
    else
      fail "Please update #{__FILE__} for adapter #{SPEC_ADAPTER}"
    end
  end

  let(:error) { adapter_error_class.new("db down!") }
  let(:timeout) { ActiveRecord::ConnectionTimeoutError.new("db lazy!") }
  let(:test_doubles) { [TestDouble.new(error, 1), TestDouble.new(timeout, 1)]  }

  before do
    @logger = double("Logger", info: nil, error: nil, warn: nil)
    allow(Rpush).to receive(:logger).and_return(@logger)

    allow(ActiveRecord::Base).to receive(:clear_all_connections!)
    allow(ActiveRecord::Base).to receive(:establish_connection)
    test_doubles.each { |td| allow(td).to receive(:sleep) }
  end

  it "should log the error raised" do
    expect(Rpush.logger).to receive(:error).with(error)
    test_doubles.each(&:perform)
  end

  it "should log that the database is being reconnected" do
    expect(Rpush.logger).to receive(:warn).with("Lost connection to database, reconnecting...")
    test_doubles.each(&:perform)
  end

  it "should log the reconnection attempt" do
    expect(Rpush.logger).to receive(:warn).with("Attempt 1")
    test_doubles.each(&:perform)
  end

  it "should clear all connections" do
    expect(ActiveRecord::Base).to receive(:clear_all_connections!)
    test_doubles.each(&:perform)
  end

  it "should establish a new connection" do
    expect(ActiveRecord::Base).to receive(:establish_connection)
    test_doubles.each(&:perform)
  end

  it "should test out the new connection by performing an exists" do
    expect(Rpush::Client::ActiveRecord::Notification).to receive(:exists?).twice
    test_doubles.each(&:perform)
  end

  context "should reconnect on" do
    [
        ::ActiveRecord::ConnectionNotEstablished,
        ::ActiveRecord::ConnectionTimeoutError,
        ::ActiveRecord::JDBCError,
        ::ActiveRecord::StatementInvalid,
        Mysql::Error,
        Mysql2::Error,
        PG::Error,
        PGError,
        SQLite3::Exception
    ].each do |error_class|
      let(:error) { error_class.new }

      it error_class.name do
        expect(ActiveRecord::Base).to receive(:establish_connection)
        test_doubles.each(&:perform)
      end
    end
  end

  context "should not reconnect on" do
    let(:error) { ActiveRecord::ActiveRecordError.new }

    it "ActiveRecord::ActiveRecordError" do
      expect(ActiveRecord::Base).not_to receive(:establish_connection)
      expect { test_doubles.each(&:perform) }.to raise_error(ActiveRecord::ActiveRecordError)
    end
  end

  context "when the reconnection attempt is not successful" do
    before do
      class << Rpush::Client::ActiveRecord::Notification
        def exists?
          @exists_calls += 1
          return if @exists_calls == 2
          fail @error
        end
      end
      Rpush::Client::ActiveRecord::Notification.instance_variable_set("@exists_calls", 0)
      Rpush::Client::ActiveRecord::Notification.instance_variable_set("@error", error)
    end

    describe "error behaviour" do
      it "should log the 2nd attempt" do
        expect(Rpush.logger).to receive(:warn).with("Attempt 2")
        test_doubles[0].perform
      end

      it "should log errors raised when the reconnection is not successful" do
        expect(Rpush.logger).to receive(:error).with(error)
        test_doubles[0].perform
      end

      it "should sleep to avoid thrashing when the database is down" do
        expect(test_doubles[0]).to receive(:sleep).with(2)
        test_doubles[0].perform
      end
    end

    describe "timeout behaviour" do
      it "should log the 2nd attempt" do
        expect(Rpush.logger).to receive(:warn).with("Attempt 2")
        test_doubles[1].perform
      end

      it "should log errors raised when the reconnection is not successful" do
        expect(Rpush.logger).to receive(:error).with(timeout)
        test_doubles[1].perform
      end

      it "should sleep to avoid thrashing when the database is down" do
        expect(test_doubles[1]).to receive(:sleep).with(2)
        test_doubles[1].perform
      end
    end
  end
end if active_record?
