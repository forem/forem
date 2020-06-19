require "spec_helper"

RSpec.describe Timber::Logger, :rails_23 => true do
  describe "#silence" do
    let(:io) { StringIO.new }
    let(:logger) { Timber::Logger.new(io) }

    it "should silence the logs" do
      logger.silence do
        logger.info("test")
      end

      expect(io.string).to eq("")
    end
  end
end
