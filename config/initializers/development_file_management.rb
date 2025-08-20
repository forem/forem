# Development File Management
# This initializer configures file management for development environment

if Rails.env.development?
  # Reduce log verbosity for better performance
  Rails.logger.level = Logger::INFO

  # Disable asset logging to reduce noise
  Rails.application.config.assets.quiet = true

  # Configure temporary file cleanup
  Rails.application.config.after_initialize do
    # Clean up old temporary files on startup
    if ENV["CLEANUP_ON_STARTUP"] == "true"
      require "fileutils"

      # Clean up old log files (older than 7 days)
      log_dir = Rails.root.join("log")
      Dir.glob(log_dir.join("*.log*")).each do |log_file|
        if File.mtime(log_file) < 7.days.ago
          File.delete(log_file)
          Rails.logger.info "Cleaned up old log file: #{log_file}"
        end
      end

      # Clean up old temporary files (older than 3 days)
      tmp_dir = Rails.root.join("tmp")
      Dir.glob(tmp_dir.join("**/*")).each do |tmp_file|
        if File.file?(tmp_file) && File.mtime(tmp_file) < 3.days.ago
          File.delete(tmp_file)
          Rails.logger.info "Cleaned up old temp file: #{tmp_file}"
        end
      end

      # Clean up empty directories
      Dir.glob(tmp_dir.join("**/*")).reverse_each do |dir|
        if File.directory?(dir) && Dir.empty?(dir)
          Dir.rmdir(dir)
          Rails.logger.info "Cleaned up empty directory: #{dir}"
        end
      end
    end
  end

  # Configure file watchers to be less aggressive
  Rails.application.config.file_watcher = ActiveSupport::EventedFileUpdateChecker

  # NOTE: File watcher configuration is handled in config/environments/development.rb
  # The EventedFileUpdateChecker is already configured there
end
