module Api
  module HealthChecksController
    extend ActiveSupport::Concern

    def app
      render json: { message: I18n.t("api.v0.health_checks_controller.app_is_up") }, status: :ok
    end

    def database
      if ActiveRecord::Base.connected?
        render json: { message: I18n.t("api.v0.health_checks_controller.database_connected") }, status: :ok
      else
        render json: { message: I18n.t("api.v0.health_checks_controller.database_not_connected") },
               status: :internal_server_error
      end
    end

    def cache
      if all_cache_instances_connected?
        render json: { message: I18n.t("api.v0.health_checks_controller.redis_connected") }, status: :ok
      else
        render json: { message: I18n.t("api.v0.health_checks_controller.redis_not_connected") },
               status: :internal_server_error
      end
    end

    private

    def authenticate_with_token
      return if request.local?

      expected_token = Settings::General.health_check_token
      provided_token = request.headers["health-check-token"]
      if expected_token.present? && provided_token.is_a?(String) &&
          ActiveSupport::SecurityUtils.secure_compare(provided_token, expected_token)
        return
      end

      error_unauthorized
    end

    def all_cache_instances_connected?
      [
        ENV.fetch("REDIS_URL", nil),
        ENV.fetch("REDIS_SESSIONS_URL", nil),
        ENV.fetch("REDIS_SIDEKIQ_URL", nil),
        ENV.fetch("REDIS_RPUSH_URL", nil),
      ].compact.all? do |url|
        Redis.new(url: url).ping == "PONG"
      end
    end
  end
end
