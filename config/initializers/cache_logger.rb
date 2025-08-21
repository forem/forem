if Rails.env.development? && Rails.configuration.action_controller.perform_caching
  ActiveSupport::Cache::Store.logger = Rails.logger
  ActiveSupport::Cache::Store.logger.level = Logger::DEBUG
else
  Rails.cache.silence!
end
