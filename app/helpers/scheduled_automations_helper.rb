module ScheduledAutomationsHelper
  def format_frequency(automation)
    case automation.frequency
    when "hourly"
      "Every hour at minute #{automation.frequency_config['minute']}"
    when "daily"
      "Daily at #{format_time(automation.frequency_config['hour'], automation.frequency_config['minute'])}"
    when "weekly"
      day_name = Date::DAYNAMES[automation.frequency_config['day_of_week']]
      "Every #{day_name} at #{format_time(automation.frequency_config['hour'], automation.frequency_config['minute'])}"
    when "custom_interval"
      interval = automation.frequency_config['interval_days']
      "Every #{interval} #{'day'.pluralize(interval)} at #{format_time(automation.frequency_config['hour'], automation.frequency_config['minute'])}"
    else
      "Unknown frequency"
    end
  end

  def format_time(hour, minute)
    Time.new(2000, 1, 1, hour, minute, 0, "+00:00").strftime("%I:%M %p UTC")
  end
end

