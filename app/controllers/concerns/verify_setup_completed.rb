# Included in the ApplicationController to assist with creator onboarding
module VerifySetupCompleted
  extend ActiveSupport::Concern

  module_function

  included do
    # rubocop:disable Rails/LexicallyScopedActionFilter
    before_action :verify_setup_completed, only: %i[index new edit show]
    # rubocop:enable Rails/LexicallyScopedActionFilter
  end

  def setup_completed?
    missing_configs.empty?
  end

  def missing_configs
    @missing_configs ||= Settings::Mandatory.missing
  end

  private

  def missing_configs_text
    display_missing = if missing_configs.size > 3
                        missing_configs.first(3) + [I18n.t("concerns.verify_setup_completed.others")]
                      else
                        missing_configs
                      end
    display_missing.map { |config| config.to_s.tr("_", " ") }.to_sentence(locale: I18n.locale)
  end

  def verify_setup_completed
    # This is the only flash in our application layout, don't override it if
    # there's already another message.
    return if flash[:global_notice].present?
    return if config_path? || setup_completed? || Settings::General.waiting_on_first_user

    link = helpers.tag.a(I18n.t("concerns.verify_setup_completed.link"), href: admin_config_path,
                                                                         data: { "no-instant" => true })

    flash[:global_notice] =
      I18n.t("concerns.verify_setup_completed.notice_html", missing: missing_configs_text, link: link)
  end

  def config_path?
    request.env["PATH_INFO"] == admin_config_path
  end
end
