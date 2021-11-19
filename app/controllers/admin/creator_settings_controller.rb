module Admin
  class CreatorSettingsController < Admin::ApplicationController
    ALLOWED_PARAMS = %i[community_name logo_svg primary_brand_color_hex invite_only_mode public checked_code_of_conduct
                        checked_terms_and_conditions].freeze

    def new; end

    def create
      extra_authorization
      ActiveRecord::Base.transaction do
        ::Settings::Community.community_name = settings_params[:community_name]
        ::Settings::General.logo_svg = settings_params[:logo_svg]
        ::Settings::UserExperience.primary_brand_color_hex = settings_params[:primary_brand_color_hex]
        ::Settings::Authentication.invite_only_mode = settings_params[:invite_only]
        ::Settings::UserExperience.public = settings_params[:public]
      end
      current_user.update!(
        saw_onboarding: true,
        checked_code_of_conduct: settings_params[:checked_code_of_conduct],
        checked_terms_and_conditions: settings_params[:checked_terms_and_conditions],
      )
      redirect_to root_path
    rescue StandardError => e
      flash.now[:error] = e.message
      render new_admin_creator_setting_path
    end

    private

    def extra_authorization
      not_authorized unless current_user.has_role?(:creator)
    end

    def settings_params
      params.permit(ALLOWED_PARAMS)
    end
  end
end
