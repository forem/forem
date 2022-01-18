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

    flash[:global_notice] = "Sidekiq is not running and is needed for the app to function properly. \
                           Use bin/startup to start the application properly.".html_safe
  end
end
