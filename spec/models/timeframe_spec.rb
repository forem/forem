require "rails_helper"

RSpec.describe Timeframe do
  it "sets timeframe for week to 1 week ago" do
    Timecop.freeze(Time.current) do
      timeframe = described_class.datetime("week")
      expect(timeframe).to eq(1.week.ago)
    end
  end

  it "sets timeframe for month to 1 month ago" do
    Timecop.freeze(Time.current) do
      timeframe = described_class.datetime("month")
      expect(timeframe).to eq(1.month.ago)
    end
  end

  it "sets timeframe for year to 1 year ago" do
    Timecop.freeze(Time.current) do
      timeframe = described_class.datetime("year")
      expect(timeframe).to eq(1.year.ago)
    end
  end

  it "sets timeframe for infinity to 5 years ago" do
    Timecop.freeze(Time.current) do
      timeframe = described_class.datetime("infinity")
      expect(timeframe).to eq(5.years.ago)
    end
  end

  describe ".datetime_iso8601" do
    it "returns ISO8601 formatted datetime string for valid timeframe" do
      Timecop.freeze(Time.current) do
        iso_string = described_class.datetime_iso8601("week")
        expected_iso = 1.week.ago.iso8601
        expect(iso_string).to eq(expected_iso)
      end
    end

    it "returns nil for latest timeframe since it's not a datetime" do
      iso_string = described_class.datetime_iso8601("latest")
      expect(iso_string).to be_nil
    end

    it "returns nil for invalid timeframe" do
      iso_string = described_class.datetime_iso8601("invalid")
      expect(iso_string).to be_nil
    end
  end
end
