class Timeframer
  attr_accessor :timeframe

  LATEST_TIMEFRAME = "latest".freeze

  FILTER_TIMEFRAMES = {
    "infinity" => 5.years.ago,
    "year" => 1.year.ago,
    "month" => 1.month.ago,
    "week" => 1.week.ago
  }.freeze

  DATETIMES = FILTER_TIMEFRAMES.merge(LATEST_TIMEFRAME: LATEST_TIMEFRAME).freeze

  def initialize(timeframe)
    @timeframe = timeframe
  end

  def datetime
    DATETIMES[timeframe]
  end
end
