class ScheduledAutomation < ApplicationRecord
  # Associations
  belongs_to :user

  # Callbacks
  before_validation :normalize_frequency_config

  # Validations
  validates :frequency, presence: true, inclusion: { in: %w[daily weekly hourly custom_interval] }
  validates :action, presence: true, inclusion: { in: %w[create_draft publish_article] }
  validates :service_name, presence: true
  validates :state, presence: true, inclusion: { in: %w[active running completed failed] }
  validate :validate_frequency_config
  validate :validate_user_is_community_bot

  # Scopes
  scope :enabled, -> { where(enabled: true) }
  scope :active, -> { where(state: "active") }
  scope :due_for_execution, -> { 
    enabled.active.where("next_run_at <= ?", Time.current)
  }

  # State management
  def running?
    state == "running"
  end

  def mark_as_running!
    update!(state: "running", updated_at: Time.current)
  end

  def mark_as_completed!(next_run_time)
    update!(
      state: "active",
      last_run_at: Time.current,
      next_run_at: next_run_time
    )
  end

  def mark_as_failed!
    update!(state: "failed")
  end

  # Calculate next run time based on frequency configuration
  def calculate_next_run_time(from_time = Time.current)
    case frequency
    when "hourly"
      calculate_hourly_next_run(from_time)
    when "daily"
      calculate_daily_next_run(from_time)
    when "weekly"
      calculate_weekly_next_run(from_time)
    when "custom_interval"
      calculate_custom_interval_next_run(from_time)
    end
  end

  # Set the next run time if not already set
  def set_next_run_time!
    return if next_run_at.present?
    
    update!(next_run_at: calculate_next_run_time)
  end

  private

  def normalize_frequency_config
    return if frequency_config.blank?

    # Convert all numeric values in frequency_config to integers
    # This ensures consistent data types when values come from forms as strings
    normalized = frequency_config.transform_values do |value|
      value.to_s.match?(/^\d+$/) ? value.to_i : value
    end
    
    self.frequency_config = normalized
  end

  def validate_frequency_config
    case frequency
    when "hourly"
      validate_hourly_config
    when "daily"
      validate_daily_config
    when "weekly"
      validate_weekly_config
    when "custom_interval"
      validate_custom_interval_config
    end
  end

  def validate_hourly_config
    # Expects: { "minute": 0-59 }
    minute = frequency_config["minute"]
    if minute.nil?
      errors.add(:frequency_config, "must include 'minute' for hourly frequency")
    else
      minute = minute.to_i
      if minute < 0 || minute > 59
        errors.add(:frequency_config, "minute must be an integer between 0 and 59")
      end
    end
  end

  def validate_daily_config
    # Expects: { "hour": 0-23, "minute": 0-59 }
    hour = frequency_config["hour"]
    minute = frequency_config["minute"]
    
    if hour.nil?
      errors.add(:frequency_config, "must include 'hour' for daily frequency")
    else
      hour = hour.to_i
      if hour < 0 || hour > 23
        errors.add(:frequency_config, "hour must be an integer between 0 and 23")
      end
    end

    if minute.nil?
      errors.add(:frequency_config, "must include 'minute' for daily frequency")
    else
      minute = minute.to_i
      if minute < 0 || minute > 59
        errors.add(:frequency_config, "minute must be an integer between 0 and 59")
      end
    end
  end

  def validate_weekly_config
    # Expects: { "day_of_week": 0-6 (0=Sunday), "hour": 0-23, "minute": 0-59 }
    day_of_week = frequency_config["day_of_week"]
    hour = frequency_config["hour"]
    minute = frequency_config["minute"]

    if day_of_week.nil?
      errors.add(:frequency_config, "must include 'day_of_week' for weekly frequency")
    else
      day_of_week = day_of_week.to_i
      if day_of_week < 0 || day_of_week > 6
        errors.add(:frequency_config, "day_of_week must be an integer between 0 (Sunday) and 6 (Saturday)")
      end
    end

    if hour.nil?
      errors.add(:frequency_config, "must include 'hour' for weekly frequency")
    else
      hour = hour.to_i
      if hour < 0 || hour > 23
        errors.add(:frequency_config, "hour must be an integer between 0 and 23")
      end
    end

    if minute.nil?
      errors.add(:frequency_config, "must include 'minute' for weekly frequency")
    else
      minute = minute.to_i
      if minute < 0 || minute > 59
        errors.add(:frequency_config, "minute must be an integer between 0 and 59")
      end
    end
  end

  def validate_custom_interval_config
    # Expects: { "interval_days": Integer, "hour": 0-23, "minute": 0-59 }
    interval_days = frequency_config["interval_days"]
    hour = frequency_config["hour"]
    minute = frequency_config["minute"]

    if interval_days.nil?
      errors.add(:frequency_config, "must include 'interval_days' for custom_interval frequency")
    else
      interval_days = interval_days.to_i
      if interval_days < 1
        errors.add(:frequency_config, "interval_days must be a positive integer")
      end
    end

    if hour.nil?
      errors.add(:frequency_config, "must include 'hour' for custom_interval frequency")
    else
      hour = hour.to_i
      if hour < 0 || hour > 23
        errors.add(:frequency_config, "hour must be an integer between 0 and 23")
      end
    end

    if minute.nil?
      errors.add(:frequency_config, "must include 'minute' for custom_interval frequency")
    else
      minute = minute.to_i
      if minute < 0 || minute > 59
        errors.add(:frequency_config, "minute must be an integer between 0 and 59")
      end
    end
  end

  def validate_user_is_community_bot
    return unless user

    unless user.community_bot?
      errors.add(:user, "must be a community bot")
    end
  end

  def calculate_hourly_next_run(from_time)
    minute = frequency_config["minute"].to_i
    next_run = from_time.change(min: minute, sec: 0)
    
    # If the time has already passed this hour, schedule for next hour
    next_run += 1.hour if next_run <= from_time
    
    next_run
  end

  def calculate_daily_next_run(from_time)
    hour = frequency_config["hour"].to_i
    minute = frequency_config["minute"].to_i
    
    next_run = from_time.change(hour: hour, min: minute, sec: 0)
    
    # If the time has already passed today, schedule for tomorrow
    next_run += 1.day if next_run <= from_time
    
    next_run
  end

  def calculate_weekly_next_run(from_time)
    day_of_week = frequency_config["day_of_week"].to_i
    hour = frequency_config["hour"].to_i
    minute = frequency_config["minute"].to_i
    
    # Calculate days until target day of week
    current_wday = from_time.wday
    days_ahead = (day_of_week - current_wday) % 7
    
    next_run = from_time.advance(days: days_ahead).change(hour: hour, min: minute, sec: 0)
    
    # If we're on the same day but the time has passed, schedule for next week
    if days_ahead == 0 && next_run <= from_time
      next_run += 1.week
    end
    
    next_run
  end

  def calculate_custom_interval_next_run(from_time)
    interval_days = frequency_config["interval_days"].to_i
    hour = frequency_config["hour"].to_i
    minute = frequency_config["minute"].to_i
    
    # If this is the first run, schedule for the specified time today or tomorrow
    if last_run_at.nil?
      next_run = from_time.change(hour: hour, min: minute, sec: 0)
      next_run += 1.day if next_run <= from_time
    else
      # Schedule based on the last run time plus the interval
      next_run = last_run_at.advance(days: interval_days).change(hour: hour, min: minute, sec: 0)
    end
    
    next_run
  end
end

