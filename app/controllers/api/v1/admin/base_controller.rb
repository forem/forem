module Api
  module V1
    module Admin
      class BaseController < Api::V1::ApiController
        include AdminApiUsersHelper

        before_action :authenticate!
        before_action :authorize_super_admin
        after_action :flush_audit, if: -> { response.successful? && @audit_payload }

        rescue_from Api::Admin::ApiError do |exc|
          render json: error_envelope(exc.message, exc.error_code, exc.status), status: exc.status
        end

        rescue_from ActiveRecord::RecordNotFound do |exc|
          render json: error_envelope(exc.message, :not_found, 404), status: :not_found
        end

        rescue_from ActiveRecord::RecordInvalid do |exc|
          render json: error_envelope(exc.message, :validation_failed, 422)
            .merge(errors: exc.record.errors.to_hash(true)), status: :unprocessable_entity
        end

        private

        # Used by action methods to declare an audit log entry.
        # The audit row is only persisted if the response is successful.
        def audit!(slug:, data:)
          @audit_payload = { slug: slug.to_s, data: data.stringify_keys }
        end

        def flush_audit
          slug = @audit_payload.fetch(:slug)
          data = @audit_payload.fetch(:data).merge("action" => slug)
          Audit::Logger.log(:admin_api, current_user, data)
        end

        def current_user
          @user
        end

        def error_envelope(message, error_code, status)
          { error: message, error_code: error_code.to_s, status: status }
        end
      end
    end
  end
end
