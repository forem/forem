module Admin
  class CreatorSettingsController < Admin::ApplicationController
    after_action :bust_content_change_caches, only: %i[create]

    ALLOWED_PARAMS = %i[checked_code_of_conduct checked_terms_and_conditions community_name
                        invite_only_mode logo primary_brand_color_hex public].freeze

    def new
      @creator_settings_form = CreatorSettingsForm.new(
        community_name: ::Settings::Community.community_name,
        public: ::Settings::UserExperience.public,
        invite_only_mode: ::Settings::Authentication.invite_only_mode,
        primary_brand_color_hex: ::Settings::UserExperience.primary_brand_color_hex,
        checked_code_of_conduct: current_user.checked_code_of_conduct,
        checked_terms_and_conditions: current_user.checked_terms_and_conditions,
      )
      @max_file_size = LogoUploader::MAX_FILE_SIZE
      @logo_allowed_types = LogoUploader::ALLOWED_TYPES
    end

    def create
      extra_authorization

      @creator_settings_form = CreatorSettingsForm.new(settings_params)
      current_user.update!(
        checked_code_of_conduct: @creator_settings_form.checked_code_of_conduct,
        checked_terms_and_conditions: @creator_settings_form.checked_terms_and_conditions,
      )

      if @creator_settings_form.save
        current_user.update!(saw_onboarding: true)
        redirect_to root_path
      else
        flash[:error] = @creator_settings_form.errors.full_messages
        redirect_to new_admin_creator_setting_path
      end
    end

    private

    def extra_authorization
      not_authorized unless current_user.creator?
    end

    def settings_params
      params.require(:creator_settings_form).permit(ALLOWED_PARAMS)
    end
  end
end
