module Admin
  class ConfigsController < Admin::ApplicationController
    include SiteConfigParams

    EMOJI_ONLY_FIELDS = %w[community_emoji].freeze
    IMAGE_FIELDS =
      %w[
        main_social_image
        logo_png
        secondary_logo_url
        campaign_sidebar_image
        mascot_image_url
        mascot_footer_image_url
        onboarding_logo_image
        onboarding_background_image
        onboarding_taskcard_image
      ].freeze

    VALID_URL = %r{\A(http|https)://([/|.\w\s-])*.[a-z]{2,5}(:[0-9]{1,5})?(/.*)?\z}.freeze

    layout "admin"

    before_action :extra_authorization_and_confirmation, only: [:create]

    def show
      @confirmation_text = confirmation_text
    end

    def create
      result = SiteConfigs::Upsert.call(site_config_params)
      if result.success?
        Audit::Logger.log(:internal, current_user, params.dup)
        bust_content_change_caches
        redirect_to admin_config_path, notice: "Site configuration was successfully updated."
      else
        redirect_to admin_config_path, alert: "😭 #{result.errors.to_sentence}"
      end
    end

    private

    def confirmation_text
      "My username is @#{current_user.username} and this action is 100% safe and appropriate."
    end

    def raise_confirmation_mismatch_error
      raise ActionController::BadRequest.new, "The confirmation key does not match"
    end

    def extra_authorization_and_confirmation
      not_authorized unless current_user.has_role?(:super_admin)
      raise_confirmation_mismatch_error if params.require(:confirmation) != confirmation_text
    end
  end
end
