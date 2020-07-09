require "spec_helper"

RSpec.describe Timber::Integrations::ActiveRecord::LogSubscriber do
  let(:time) { Time.utc(2016, 9, 1, 12, 0, 0) }
  let(:io) { StringIO.new }
  let(:logger) do
    logger = Timber::Logger.new(io)
    logger.level = ::Logger::INFO
    logger
  end

  describe "#insert!" do
    around(:each) do |example|
      with_rails_logger(logger) do
        Timecop.freeze(time) { example.run }
      end
    end

    it "should not log if the level is not sufficient" do
      ActiveRecord::Base.connection.execute("select * from users")
      expect(io.string).to eq("")
    end

    context "with an info level" do
      around(:each) do |example|
        old_level = logger.level
        logger.level = ::Logger::DEBUG
        example.run
        logger.level = old_level
      end

      it "should log the sql query" do
        ActiveRecord::Base.connection.execute("select * from users")
        # Rails 4.X adds random spaces :/
        string = io.string.gsub("   ORDER BY", " ORDER BY")
        string = string.gsub("  ORDER BY", " ORDER BY")
        expect(string).to include("select * from users")
        expect(string).to include("duration_ms")
        expect(string).to include("\"level\":\"debug\"")
        expect(string).to include("\"sql_query_executed\":")
      end
    end
  end
end
