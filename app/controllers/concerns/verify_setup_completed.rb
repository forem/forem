module VerifySetupCompleted
  extend ActiveSupport::Concern

  MANDATORY_CONFIGS = %i[community_description shop_url].freeze
  private_constant :MANDATORY_CONFIGS

  included do
    # rubocop:disable Rails/LexicallyScopedActionFilter
    before_action :verify_setup_completed, only: %i[index new edit show]
    # rubocop:enable Rails/LexicallyScopedActionFilter
  end

  private

  def verify_setup_completed
    return if setup_completed? || config_path?

    link = helpers.link_to("the configuration page", internal_config_path)
    # rubocop:disable Rails/OutputSafety
    flash[:global_notice] = "Setup not completed yet, please visit #{link}.".html_safe
    # rubocop:enable Rails/OutputSafety
  end

  def setup_completed?
    MANDATORY_CONFIGS.all? { |config| SiteConfig.public_send(config).present? }
  end

  def config_path?
    request.env["PATH_INFO"] == internal_config_path
  end
end
