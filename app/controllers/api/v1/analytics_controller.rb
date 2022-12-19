module Api
  module V1
    class AnalyticsController < ApiController
      respond_to :json

      rescue_from ArgumentError, with: :error_unprocessable_entity
      rescue_from ApplicationPolicy::NotAuthorizedError, with: :error_unauthorized

      include Api::AnalyticsController

      before_action :authenticate_with_api_key_or_current_user!
      before_action :authorize_user_organization
      before_action :load_owner
      before_action :validate_date_params, only: [:historical]
    end
  end
end
