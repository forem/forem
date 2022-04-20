module Users
  class OnboardingsController < ApplicationController
    before_action :authenticate_user!
    before_action :set_cache_control_headers, only: [:show]
    before_action :set_no_cache_header, only: [:update]
    after_action :verify_authorized, only: [:update]

    ALLOWED_USER_PARAMS = %i[checked_code_of_conduct checked_terms_and_conditions saw_onboarding last_onboarding_page
                             username].freeze

    def show
      set_surrogate_key_header "onboarding-slideshow"
    end

    def update
      authorize current_user

      if params[:user]
        user_update
      elsif params[:notifications]
        notifications_update
      end
    end

    private

    def user_update
      if params[:user]
        if unset_username?
          return render json: { errors: I18n.t("users_controller.username_blank") }, status: :unprocessable_entity
        end

        params[:user].compact_blank!
      end

      update_result = Users::Update.call(current_user, user: user_params, profile: profile_params)

      if update_result.success?
        render json: {}, status: :ok
      else
        render json: { errors: update_result.errors_as_sentence }, status: :unprocessable_entity
      end

    end

    def notifications_update
      notification_setting = current_user.notification_setting
      notification_setting.assign_attributes(notification_params)

      if notification_setting.save
        render json: {}, status: :ok
      else
        render json: { errors: current_user.notification_setting.errors_as_sentence }, status: :unprocessable_entity
      end
    end

    def unset_username?
      params[:user].key?(:username) && params[:user][:username].blank?
    end

    def user_params
      params[:user].permit(ALLOWED_USER_PARAMS)
    end

    def notification_params
      params[:notifications].permit(%i[email_newsletter email_digest_periodic])
    end

    def profile_params
      params[:profile] ? params[:profile].permit(Profile.static_fields + Profile.attributes) : nil
    end
  end
end
