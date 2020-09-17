class Timeframer
  attr_accessor :timeframe

  LATEST_TIMEFRAME = "latest".freeze
  FILTER_TIMEFRAMES = %w[infinity year month week].freeze

  def initialize(timeframe)
    @timeframe = timeframe
  end

  def datetime
    datetimes[timeframe]
  end

  private

  def datetimes
    @datetimes ||= {
      infinity: 5.years.ago,
      year: 1.year.ago,
      month: 1.month.ago,
      week: 1.week.ago,
      LATEST_TIMEFRAME: LATEST_TIMEFRAME
    }.with_indifferent_access
  end
end
