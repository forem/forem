module Api
  module V0
    class HealthChecksController < ApiController
      before_action :authenticate_with_token

      def app
        render json: { message: "App is up!" }, status: :ok
      end

      def search
        if Search::Client.ping
          render json: { message: "Search ping succeeded!" }, status: :ok
        else
          render json: { message: "Search ping failed!" }, status: :internal_server_error
        end
      end

      def database
        if ActiveRecord::Base.connected?
          render json: { message: "Database connected" }, status: :ok
        else
          render json: { message: "Database NOT connected!" }, status: :internal_server_error
        end
      end

      private

      def authenticate_with_token
        key = request.headers["health-check-token"]

        return if key == SiteConfig.health_check_token

        error_unauthorized
      end
    end
  end
end
