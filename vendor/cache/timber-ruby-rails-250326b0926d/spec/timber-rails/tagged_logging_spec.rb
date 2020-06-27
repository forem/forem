require "spec_helper"

RSpec.describe ActiveSupport::TaggedLogging, :rails_23 => true do
  describe "#new" do
    let(:io) { StringIO.new }

    it "should instantiate for Timber::Logger object" do
      ActiveSupport::TaggedLogging.new(Timber::Logger.new(io))
    end

    if defined?(ActiveSupport::BufferedLogger)
      it "should instantiate for a ActiveSupport::BufferedLogger object" do
        ActiveSupport::TaggedLogging.new(ActiveSupport::BufferedLogger.new(io))
      end
    end
  end

  describe "#info" do
    let(:time) { Time.utc(2016, 9, 1, 12, 0, 0) }
    let(:io) { StringIO.new }
    let(:logger) { ActiveSupport::TaggedLogging.new(Timber::Logger.new(io)) }

    it "should accept events as the second argument" do
      logger.info("SQL query", payment_rejected: {customer_id: "abcd1234", amount: 100, reason: "Card expired"})
      expect(io.string).to include("SQL query")
      expect(io.string).to include("\"payment_rejected\":")
    end
  end
end
