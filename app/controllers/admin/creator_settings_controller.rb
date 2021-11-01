module Admin
  class CreatorSettingsController < Admin::ApplicationController
    ALLOWED_PARAMS = %i[community_name logo_svg primary_brand_color_hex invite_only_mode public].freeze

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
      # For this feature to work as expected for the time being, we must set the COC and TOS to true.
      # However, this is not a viable solution, as Forem Creators are required to see and check the
      # COC and TOS. Bypassing them in this manner will not do and we will need to rethink this solution.
      # TODO: Replace the current solution of setting the COC and TOS to true with a better, more
      # long-term solution for Forem Creators.
      current_user.update!(saw_onboarding: true, checked_code_of_conduct: true, checked_terms_and_conditions: true)
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
