module Admin
  class CreatorSettingsController < Admin::ApplicationController
    ALLOWED_PARAMS = %i[checked_code_of_conduct checked_terms_and_conditions community_name
                        invite_only_mode logo primary_brand_color_hex public].freeze

    def new
      @max_file_size = LogoUploader::MAX_FILE_SIZE
      @logo_allowed_types = (LogoUploader::CONTENT_TYPE_ALLOWLIST +
        LogoUploader::EXTENSION_ALLOWLIST.map { |extension| ".#{extension}" }).join(",")
    end

    def create
      extra_authorization
      ActiveRecord::Base.transaction do
        ::Settings::Community.community_name = settings_params[:community_name]
        ::Settings::UserExperience.primary_brand_color_hex = settings_params[:primary_brand_color_hex]
        ::Settings::Authentication.invite_only_mode = settings_params[:invite_only]
        ::Settings::UserExperience.public = settings_params[:public]

        if settings_params[:logo]
          logo_uploader = upload_logo(settings_params[:logo])
          ::Settings::General.original_logo = logo_uploader.url
          # An SVG will not be resized, hence we apply the OR statements below to populate SETTINGS consistently.
          ::Settings::General.resized_logo = logo_uploader.resized_logo.url || logo_uploader.url
        end
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

    def upload_logo(image)
      LogoUploader.new.tap do |uploader|
        uploader.store!(image)
      end
    end
  end
end
