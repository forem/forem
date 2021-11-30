module Admin
  class CreatorSettingsController < Admin::ApplicationController
    ALLOWED_PARAMS = %i[community_name primary_brand_color_hex invite_only_mode public checked_code_of_conduct
                        checked_terms_and_conditions logo].freeze

    def new
      @max_file_size = LogoUploader::MAX_FILE_SIZE
      @logo_allowed_types = (LogoUploader::CONTENT_TYPE_ALLOWLIST +
        LogoUploader::EXTENSION_ALLOWLIST.map { |extension| ".#{extension}" }).join(",")
    end

    def create
      extra_authorization

      raise CarrierWave::IntegrityError if settings_params[:logo].blank?

      ActiveRecord::Base.transaction do
        logo_uploader = upload_logo(settings_params[:logo])
        ::Settings::General.original_logo = logo_uploader.url
        # An SVG will not be resized, hence we apply the OR statements below to populate SETTINGS consistently.
        ::Settings::General.resized_logo = logo_uploader.resized_logo.url || logo_uploader.url

        ::Settings::Community.community_name = settings_params[:community_name]
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

    def upload_logo(image)
      LogoUploader.new.tap do |uploader|
        uploader.store!(image)
      end
    end
  end
end
