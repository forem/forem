class Timeframer
  attr_accessor :timeframe

  DATETIMES = {
    "infinity" => 5.years.ago,
    "year" => 1.year.ago,
    "month" => 1.month.ago,
    "week" => 1.week.ago,
    "latest" => "latest"
  }.freeze

  def initialize(timeframe)
    @timeframe = timeframe
  end

  def datetime
    DATETIMES[timeframe]
  end
end
