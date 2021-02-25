module VerifySetupCompleted
  extend ActiveSupport::Concern

  module_function

  MANDATORY_CONFIGS = %i[
    community_name
    community_description

    suggested_tags
    suggested_users
  ].freeze

  included do
    # rubocop:disable Rails/LexicallyScopedActionFilter
    before_action :verify_setup_completed, only: %i[index new edit show]
    # rubocop:enable Rails/LexicallyScopedActionFilter
  end

  def setup_completed?
    missing_configs.empty?
  end

  def missing_configs
    @missing_configs ||= MANDATORY_CONFIGS.reject { |config| SiteConfig.public_send(config).present? }
  end

  private

  def missing_configs_text
    display_missing = missing_configs.size > 3 ? missing_configs.first(3) + ["others"] : missing_configs
    display_missing.map { |c| c.to_s.tr("_", " ") }.to_sentence
  end

  def verify_setup_completed
    # This is the only flash in our application layout, don't override it if
    # there's already another message.
    return if flash[:global_notice].present?
    return if config_path? || setup_completed? || SiteConfig.waiting_on_first_user

    link = helpers.tag.a("the configuration page", href: admin_config_path, data: { "no-instant" => true })

    flash[:global_notice] = helpers.safe_join(["Setup not completed yet, missing ",
                                               missing_configs_text,
                                               ". Please visit ", link, "."])
  end

  def config_path?
    request.env["PATH_INFO"] == admin_config_path
  end
end
