class Timeframe
  LATEST_TIMEFRAME = "latest".freeze
  FILTER_TIMEFRAMES = %w[all-time this-year this-month this-week].freeze

  def self.datetime(timeframe)
    datetimes[timeframe]
  end

  def self.datetime_iso8601(timeframe)
    datetime(timeframe)&.iso8601
  end

  def self.datetimes
    {
      "all-time": 5.years.ago,
      "this-year": 1.year.ago,
      "this-month": 1.month.ago,
      "this-week": 1.week.ago,
      LATEST_TIMEFRAME: LATEST_TIMEFRAME
    }.with_indifferent_access
  end
  private_class_method :datetimes
end
