require "rails_helper"

RSpec.describe Timeframe, type: :model do
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
end
