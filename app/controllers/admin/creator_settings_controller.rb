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

      params = settings_params[:creator_settings_form]
      @creator_settings_form = CreatorSettingsForm.new(params)
      # CreatorSettingsForm.new(community_name: "gdfghja", invite_only_mode: true, primary_brand_color_hex: "#3030a1",
      # public: true, checked_code_of_conduct: true, checked_terms_and_conditions: true).save
      if @creator_settings_form.save
        current_user.update!(
          saw_onboarding: true,
          checked_code_of_conduct: params[:checked_code_of_conduct],
          checked_terms_and_conditions: params[:checked_terms_and_conditions],
        )
        redirect_to root_path
      else
        flash.now[:error] = @creator_settings_form.errors.full_messages
        render new_admin_creator_setting_path
      end
    end

    private

    def extra_authorization
      not_authorized unless current_user.has_role?(:creator)
    end

    def settings_params
      params.permit(creator_settings_form: ALLOWED_PARAMS)
    end

    def upload_logo(image)
      LogoUploader.new.tap do |uploader|
        uploader.store!(image)
      end
    end
  end
end
