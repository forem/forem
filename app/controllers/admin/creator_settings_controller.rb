module Admin
  class CreatorSettingsController < Admin::ApplicationController
    ALLOWED_PARAMS = %i[checked_code_of_conduct checked_terms_and_conditions community_name
                        invite_only_mode logo primary_brand_color_hex public].freeze

    def new
      @creator_settings_form = CreatorSettingsForm.new
      @max_file_size = LogoUploader::MAX_FILE_SIZE
      @logo_allowed_types = (LogoUploader::CONTENT_TYPE_ALLOWLIST +
        LogoUploader::EXTENSION_ALLOWLIST.map { |extension| ".#{extension}" }).join(",")
    end

    def create
      extra_authorization

      @creator_settings_form = CreatorSettingsForm.new(settings_params)
      @creator_settings_form.save
      if @creator_settings_form.success
        current_user.update!(
          saw_onboarding: true,
          checked_code_of_conduct: @creator_settings_form.checked_code_of_conduct,
          checked_terms_and_conditions: @creator_settings_form.checked_terms_and_conditions,
        )
        redirect_to root_path
      else
        flash[:error] = @creator_settings_form.errors.full_messages
        render :new
      end
    end

    private

    def extra_authorization
      not_authorized unless current_user.has_role?(:creator)
    end

    def settings_params
      params.require(:creator_settings_form).permit(ALLOWED_PARAMS)
    end
  end
end
