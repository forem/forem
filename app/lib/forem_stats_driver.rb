class ForemStatsDriver
  def self.select_driver
    # Currently, this only supports the default Datadog driver.
    # Logic will be added here for selecting the correct driver based on
    # the existence of configuration files for the desired stats recipient.
    ForemStatsDrivers::DatadogDriver
  end

  def initialize(*_args)
    @driver = self.class.select_driver.new
  end

  def increment(*args)
    @driver.increment(*args)
  end

  def count(*args)
    @driver.increment(*args)
  end

  def time(*args)
    @driver.time(*args)
  end

  def gauge(*args)
    @driver.gauge(*args)
  end
end
