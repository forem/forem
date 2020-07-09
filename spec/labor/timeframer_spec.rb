require "rails_helper"

RSpec.describe Timeframer, type: :labor do
  it "sets timeframe for week to 1 week ago" do
    Timecop.freeze(Time.current) do
      timeframer = described_class.new("week")
      expect(timeframer.datetime).to eq(1.week.ago)
    end
  end

  it "sets timeframe for month to 1 month ago" do
    Timecop.freeze(Time.current) do
      timeframer = described_class.new("month")
      expect(timeframer.datetime).to eq(1.month.ago)
    end
  end

  it "sets timeframe for year to 1 year ago" do
    Timecop.freeze(Time.current) do
      timeframer = described_class.new("year")
      expect(timeframer.datetime).to eq(1.year.ago)
    end
  end

  it "sets timeframe for infinity to 5 years ago" do
    Timecop.freeze(Time.current) do
      timeframer = described_class.new("infinity")
      expect(timeframer.datetime).to eq(5.years.ago)
    end
  end
end
