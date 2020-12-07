class Timeframe
  LATEST_TIMEFRAME = "latest".freeze
  FILTER_TIMEFRAMES = %w[infinity year month week].freeze

  def self.datetime(timeframe)
    new(timeframe).datetime
  end

  def self.datetime_iso8601
    new(timeframe).datetime&.iso8601
  end

  def initialize(timeframe)
    @timeframe = timeframe
  end

  def datetime
    datetimes[timeframe]
  end

  private

  attr_accessor :timeframe

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
