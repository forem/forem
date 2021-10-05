module Admin
  class CreatorSettingsController < Admin::ApplicationController
    before_action :extra_authorization, only: [:create]

    ALLOWED_PARAMS = %i[community_name logo_svg primary_brand_color_hex invite_only_mode public].freeze

    def new; end

    def create
      ActiveRecord::Base.transaction do
        ::Settings::Community.community_name = settings_params[:community_name]
        ::Settings::General.logo_svg = settings_params[:logo_svg]
        ::Settings::UserExperience.primary_brand_color_hex = settings_params[:primary_brand_color_hex]
        ::Settings::Authentication.invite_only_mode = settings_params[:invite_only]
        ::Settings::UserExperience.public = settings_params[:public]
      end
      current_user.update!(saw_onboarding: true)
      redirect_to root_path
    rescue StandardError => e
      flash.now[:error] = e.message
      render new_admin_creator_setting_path
    end

    private

    def extra_authorization
      not_authorized unless current_user.has_role?(:super_admin)
    end

    def settings_params
      params.permit(ALLOWED_PARAMS)
    end
  end
end
