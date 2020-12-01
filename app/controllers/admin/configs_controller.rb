module Admin
  class ConfigsController < Admin::ApplicationController
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

    VALID_URL = %r{\A(http|https)://([/|.|\w|\s|-])*.[a-z]{2,5}(:[0-9]{1,5})?(/.*)?\z}.freeze

    layout "admin"

    before_action :extra_authorization_and_confirmation, only: [:create]
    after_action :bust_content_change_caches, only: [:create]

    def show
      @confirmation_text = confirmation_text
    end

    def create
      result = SiteConfigs::Upsert.call(config_params)
      if result[:result] == "errors"
        redirect_to admin_config_path, alert: "😭 #{result[:errors]}"
        return
      end
      redirect_to admin_config_path, notice: "Site configuration was successfully updated."
    end

    private

    def confirmation_text
      "My username is @#{current_user.username} and this action is 100% safe and appropriate."
    end

    def config_params
      special_params_to_remove = %w[authentication_providers email_addresses meta_keywords credit_prices_in_cents]
      special_params_to_add = %w[auth_providers_to_enable]
      has_emails = params.dig(:site_config, :email_addresses).present?
      params[:site_config][:email_addresses][:default] = ApplicationConfig["DEFAULT_EMAIL"] if has_emails
      params&.require(:site_config)&.permit(
        (SiteConfig.keys - special_params_to_remove + special_params_to_add).map(&:to_sym),
        authentication_providers: [],
        social_media_handles: SiteConfig.social_media_handles.keys,
        email_addresses: SiteConfig.email_addresses.keys,
        meta_keywords: SiteConfig.meta_keywords.keys,
        credit_prices_in_cents: SiteConfig.credit_prices_in_cents.keys,
      )
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
