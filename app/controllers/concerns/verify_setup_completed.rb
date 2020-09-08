module VerifySetupCompleted
  extend ActiveSupport::Concern

  module_function

  MANDATORY_CONFIGS = %i[
    community_name
    community_description
    community_action
    tagline

    main_social_image
    logo_png

    mascot_user_id
    mascot_image_url

    meta_keywords

    suggested_tags
    suggested_users
  ].freeze

  included do
    # rubocop:disable Rails/LexicallyScopedActionFilter
    before_action :verify_setup_completed, only: %i[index new edit show]
    # rubocop:enable Rails/LexicallyScopedActionFilter
  end

  def setup_completed?
    MANDATORY_CONFIGS.all? { |config| SiteConfig.public_send(config).present? }
  end

  private

  def verify_setup_completed
    return if config_path? || setup_completed? || SiteConfig.waiting_on_first_user

    link = helpers.link_to("the configuration page", admin_config_path, "data-no-instant" => true)
    # rubocop:disable Rails/OutputSafety
    flash[:global_notice] = "Setup not completed yet, please visit #{link}.".html_safe
    # rubocop:enable Rails/OutputSafety
  end

  def config_path?
    request.env["PATH_INFO"] == admin_config_path
  end
end
