module Api
  module V0
    class HealthChecksController < ApiController
      def app
        render json: { message: "App is up!" }, status: :ok
      end

      def database
        if ActiveRecord::Base.connected?
          render json: { message: "Database connected" }, status: :ok
        else
          render json: { message: "Database NOT connected!" }, status: :internal_server_error
        end
      end

      def cache
        if all_cache_instances_connected?
          render json: { message: "Redis connected" }, status: :ok
        else
          render json: { message: "Redis NOT connected!" }, status: :internal_server_error
        end
      end

      private

      def all_cache_instances_connected?
        [
          ENV["REDIS_URL"],
          ENV["REDIS_SESSIONS_URL"],
          ENV["REDIS_SIDEKIQ_URL"],
          ENV["REDIS_RPUSH_URL"],
        ].compact.all? do |url|
          Redis.new(url: url).ping == "PONG"
        end
      end
    end
  end
end
