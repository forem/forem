module Users
  class OnboardingsController < ApplicationController
    before_action :authenticate_user!
    before_action :set_no_cache_header, only: %i[onboarding_checkbox_update]
    after_action :verify_authorized

    ALLOWED_CHECKBOX_PARAMS = %i[checked_code_of_conduct checked_terms_and_conditions].freeze

    def onboarding_checkbox_update
      if params[:user]
        current_user.assign_attributes(params[:user].permit(ALLOWED_CHECKBOX_PARAMS))
      end

      current_user.saw_onboarding = true
      authorize User

      if current_user.save
        render json: {}, status: :ok
      else
        render json: { errors: errors }, status: :unprocessable_entity
      end
    end
  end
end
