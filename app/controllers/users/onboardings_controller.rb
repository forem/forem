module Users
  class OnboardingsController < ApplicationController
    before_action :authenticate_user!
    before_action :set_cache_control_headers, only: [:show]
    before_action :set_no_cache_header, only: %i[update onboarding_checkbox_update]
    after_action :verify_authorized, except: [:show]

    ALLOWED_USER_PARAMS = %i[last_onboarding_page username].freeze
    ALLOWED_CHECKBOX_PARAMS = %i[checked_code_of_conduct checked_terms_and_conditions].freeze

    def show
      set_surrogate_key_header "onboarding-slideshow"
    end

    def update
      authorize User, :onboarding_update?

      user_params = {}

      if params[:user]
        if unset_username?
          return render json: { errors: I18n.t("users_controller.username_blank") }, status: :unprocessable_entity
        end

        sanitize_user_params
        user_params = params[:user].permit(ALLOWED_USER_PARAMS)
      end

      update_result = Users::Update.call(current_user, user: user_params, profile: profile_params)

      if update_result.success?
        render json: {}, status: :ok
      else
        render json: { errors: update_result.errors_as_sentence }, status: :unprocessable_entity
      end
    end

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

    private

    def unset_username?
      params[:user].key?(:username) && params[:user][:username].blank?
    end

    def sanitize_user_params
      params[:user].compact_blank!
    end

    def profile_params
      params[:profile]&.permit(Profile.static_fields + Profile.attributes)
    end
  end
end
