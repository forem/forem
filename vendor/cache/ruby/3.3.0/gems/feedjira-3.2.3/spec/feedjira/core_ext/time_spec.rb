# frozen_string_literal: true

require "spec_helper"

RSpec.describe Time do
  describe "#parse_safely" do
    it "returns the datetime in utc when given a Time" do
      time = described_class.now

      expect(described_class.parse_safely(time)).to eq(time.utc)
    end

    it "returns the datetime in utc when given a Date" do
      date = Date.today

      expect(described_class.parse_safely(date)).to eq(date.to_time.utc)
    end

    it "returns the datetime in utc when given a String" do
      timestamp = "2016-01-01 00:00:00"

      expect(described_class.parse_safely(timestamp)).to eq(described_class.parse(timestamp).utc)
    end

    it "returns nil when given an empty String" do
      timestamp = ""

      expect(described_class.parse_safely(timestamp)).to be_nil
    end

    it "returns the the datetime in utc given a 14-digit time" do
      time = described_class.now.utc
      timestamp = time.strftime("%Y%m%d%H%M%S")

      expect(described_class.parse_safely(timestamp)).to eq(time.floor)
    end

    context "when given an invalid time string" do
      it "returns nil" do
        timestamp = "2016-51-51 00:00:00"

        expect(described_class.parse_safely(timestamp)).to be_nil
      end

      it "logs an error" do
        timestamp = "2016-51-51 00:00:00"

        expect(Feedjira.logger)
          .to receive(:debug).with("Failed to parse time #{timestamp}")
        expect(Feedjira.logger)
          .to receive(:debug).with(an_instance_of(ArgumentError))

        described_class.parse_safely(timestamp)
      end
    end
  end
end
