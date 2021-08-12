module Admin
  class CreatorSettingsController < Admin::ApplicationController
    # before_action :extra_authorization, only: [:create]

    def create
      # where should I redirect the user to after updating/failing to update the settings_params?
      # should I redirect back to `/enter?state=new-user` or `/enter`?
      # As far as I know, it's necessary to redirect after this occurs in order for the flash 
      # message to show. If that's not that case, perhaps I could use flash.now to immediately render
      # the flash message instead?
      # result = settings_params.find_or_create_by

      # if result.save
      #   redirect_to admin_config_path, notice: "Successfully updated settings."
      # else
      #   redirect_to admin_config_path, alert: "😭 #{result.errors.to_sentence}"
      # end

      # settings = :bulk_settings_update.to_s.classify.constantize
      # result = settings.new(settings_params)

      # if result.save
      #   redirect_to admin_creator_settings_path, notice: "Successfully updated settings."
      # else
      #   redirect_to admin_creator_settings_path, alert: "😭 #{result.errors.to_sentence}"
      # end

      Settings::Community.community_name = settings_params[:community_name]
      Settings::General.logo_svg = settings_params[:logo_svg]
      Settings::UserExperience.primary_brand_color_hex = settings_params[:primary_brand_color_hex]
      Settings::Authentication.invite_only = settings_params[:invite_only]
      Settings::UserExperience.public = settings_params[:public]
    end

    private

    def extra_authorization
      not_authorized unless current_user.has_role?(:super_admin)
    end

    def settings_params
      allowed_params = [community_name: Settings::Community.community_name,
                        logo_svg: Settings::General.logo_svg,
                        primary_brand_color_hex: Settings::UserExperience.primary_brand_color_hex,
                        invite_only: Settings::Authentication.invite_only,
                        public: Settings::UserExperience.public]
                        # Now that I'm switching over to a form_tag form, how to I rework these params?
                        # I should look at the controllers for the other form_tag forms in the codebase
      params.permit(allowed_params)
    end
  end
end
