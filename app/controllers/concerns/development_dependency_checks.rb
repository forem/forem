# Used to warn the developer if sidekiq is not running
# Only included in ApplicationController when in development environment
module DevelopmentDependencyChecks
  extend ActiveSupport::Concern

  included do
    before_action :verify_sidekiq_running, only: %i[index show], if: proc { Rails.env.development? }
  end

  private

  def verify_sidekiq_running
    # Check if Sidekiq is running with a small retry mechanism
    # This helps with timing issues where Sidekiq might not be fully registered yet
    sidekiq_running = false
    3.times do |i|
      sidekiq_running = Sidekiq::ProcessSet.new.size.positive?
      break if sidekiq_running

      sleep(0.1) if i < 2 # Small delay before retry
    rescue StandardError => e
      Rails.logger.debug { "Sidekiq health check attempt #{i + 1} failed: #{e.message}" }
      sleep(0.1) if i < 2
    end

    return if sidekiq_running

    flash[:global_notice] = "Sidekiq is not running and is needed for the app to function properly. \
                           Use bin/startup-local to start the application properly.".html_safe
  end
end
