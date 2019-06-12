class Timeframer
  attr_accessor :timeframe
  def initialize(timeframe)
    @timeframe = timeframe
  end

  def datetime
    if timeframe == "infinity"
      5.years.ago
    elsif timeframe == "week"
      1.week.ago
    elsif timeframe == "month"
      1.month.ago
    elsif timeframe == "year"
      1.year.ago
    elsif timeframe == "latest"
      "latest"
    end
  end
end
