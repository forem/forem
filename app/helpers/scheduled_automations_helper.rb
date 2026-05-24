module ScheduledAutomationsHelper
  def format_frequency(automation)
    case automation.frequency
    when "hourly"
      minute = automation.frequency_config['minute'].to_i
      "Every hour at minute #{minute}"
    when "daily"
      hour = automation.frequency_config['hour'].to_i
      minute = automation.frequency_config['minute'].to_i
      "Daily at #{format_time(hour, minute)}"
    when "weekly"
      day_of_week = automation.frequency_config['day_of_week'].to_i
      hour = automation.frequency_config['hour'].to_i
      minute = automation.frequency_config['minute'].to_i
      day_name = Date::DAYNAMES[day_of_week]
      "Every #{day_name} at #{format_time(hour, minute)}"
    when "custom_interval"
      interval = automation.frequency_config['interval_days'].to_i
      hour = automation.frequency_config['hour'].to_i
      minute = automation.frequency_config['minute'].to_i
      "Every #{interval} #{'day'.pluralize(interval)} at #{format_time(hour, minute)}"
    else
      "Unknown frequency"
    end
  end

  def format_time(hour, minute)
    Time.new(2000, 1, 1, hour, minute, 0, "+00:00").strftime("%I:%M %p UTC")
  end
end

