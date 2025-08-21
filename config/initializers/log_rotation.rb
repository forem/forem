# Log Rotation Configuration
# This initializer configures automatic log rotation for development and test environments

if Rails.env.development?
  # Configure log rotation for development
  Rails.logger = ActiveSupport::Logger.new(
    Rails.root.join("log/development.log"),
    5, # Keep 5 rotated files
    1.megabytes, # Rotate when file reaches 1MB
  )

  # Add timestamp to log entries
  Rails.logger.formatter = proc do |severity, datetime, progname, msg|
    "#{datetime.strftime('%Y-%m-%d %H:%M:%S')} [#{severity}] #{msg}\n"
  end
elsif Rails.env.test?
  # Configure log rotation for test
  Rails.logger = ActiveSupport::Logger.new(
    Rails.root.join("log/test.log"),
    3, # Keep 3 rotated files
    1.megabytes, # Rotate when file reaches 1MB
  )

  # Add timestamp to log entries
  Rails.logger.formatter = proc do |severity, datetime, progname, msg|
    "#{datetime.strftime('%Y-%m-%d %H:%M:%S')} [#{severity}] #{msg}\n"
  end
end
