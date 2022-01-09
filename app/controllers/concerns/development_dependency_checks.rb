# Used to warn the developer if sidekiq is not running
# Only included in ApplicationController when in development environment
module DevelopmentDependencyChecks
  extend ActiveSupport::Concern

  included do
    before_action :verify_sidekiq_running, only: %i[index show], if: proc { Rails.env.development? }
  end

  private

  def verify_sidekiq_running
    return if Sidekiq::ProcessSet.new.size.positive?

    flash[:global_notice] = I18n.t("concerns.development_dependency_checks.sidekiq_is_not_running_and")
  end
end
