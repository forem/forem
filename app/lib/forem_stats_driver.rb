class ForemStatsDriver
  def initialize(*_args)
    @driver = select_driver.new
  end

  delegate(:increment, :time, :gauge, to: :@driver)
  alias count increment

  private

  def select_driver
    # Currently, this only supports the default Datadog driver.
    # Logic will be added here for selecting the correct driver based on
    # the existence of configuration files for the desired stats recipient.
    ForemStatsDrivers::DatadogDriver
  end
end
