module Admin
  class CreatorSettingsController < Admin::ApplicationController
    # before_action :extra_authorization, only: [:create]

    def create
      # binding.pry
      ::Settings::Community.community_name = settings_params[:community_name]
      ::Settings::General.logo_svg = settings_params[:logo_svg]
      ::Settings::UserExperience.primary_brand_color_hex = settings_params[:primary_brand_color_hex]
      ::Settings::Authentication.invite_only_mode = settings_params[:invite_only]
      ::Settings::UserExperience.public = settings_params[:public]
    end

    private

    def extra_authorization
      not_authorized unless current_user.has_role?(:super_admin)
    end

    def settings_params
      allowed_params = { community_name: ::Settings::Community.community_name,
                         logo_svg: ::Settings::General.logo_svg,
                         primary_brand_color_hex: ::Settings::UserExperience.primary_brand_color_hex,
                         invite_only_mode: ::Settings::Authentication.invite_only_mode,
                         public: ::Settings::UserExperience.public }
                        # binding.pry
      params.permit(allowed_params.keys)
    end
  end
end
