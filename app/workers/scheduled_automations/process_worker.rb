module ScheduledAutomations
  ##
  # Worker that processes scheduled automations that are due for execution.
  # This worker runs every 10 minutes via cron and executes all automations
  # that have a next_run_at time in the past 10 minutes.
  class ProcessWorker
    include Sidekiq::Job

    sidekiq_options queue: :default, retry: 3

    # Process all scheduled automations that are due
    def perform
      Rails.logger.info("ScheduledAutomations::ProcessWorker: Starting execution cycle")

      # Auto-create warm welcome badge automation if badge exists
      ensure_warm_welcome_automation_exists

      # Find all automations due for execution
      # We look for automations scheduled in the last 10 minutes to avoid missing any
      # due to timing issues
      automations = ScheduledAutomation
                      .due_for_execution
                      .where("next_run_at >= ?", 10.minutes.ago)
                      .order(next_run_at: :asc)

      if automations.empty?
        Rails.logger.info("ScheduledAutomations::ProcessWorker: No automations due for execution")
        return
      end

      Rails.logger.info("ScheduledAutomations::ProcessWorker: Found #{automations.count} automation(s) to execute")

      # Execute each automation
      automations.find_each do |automation|
        execute_automation(automation)
      end

      Rails.logger.info("ScheduledAutomations::ProcessWorker: Execution cycle complete")
    end

    private

    def ensure_warm_welcome_automation_exists
      badge_id = Badge.id_for_slug("warm-welcome")
      return unless badge_id

      # Check if automation already exists
      existing = ScheduledAutomation.find_by(
        action: "award_warm_welcome_badge",
        service_name: "warm_welcome_badge"
      )
      return if existing

      # Find a community bot user (use first available)
      bot = User.where(type_of: :community_bot).first
      unless bot
        Rails.logger.warn("ScheduledAutomations::ProcessWorker: No community bot found, cannot create warm welcome automation")
        return
      end

      # Calculate next Friday at 9 AM
      # Use the automation's calculate_next_run_time method logic for weekly
      now = Time.current
      day_of_week = 5 # Friday
      hour = 9
      minute = 0
      
      # Calculate days until target day of week
      current_wday = now.wday
      days_ahead = (day_of_week - current_wday) % 7
      
      next_friday = now.advance(days: days_ahead).change(hour: hour, min: minute, sec: 0)
      
      # If we're on the same day but the time has passed, schedule for next week
      if days_ahead == 0 && next_friday <= now
        next_friday += 1.week
      end

      # Create the automation
      automation = ScheduledAutomation.create!(
        user: bot,
        frequency: "weekly",
        frequency_config: {
          "day_of_week" => 5, # Friday
          "hour" => 9,
          "minute" => 0
        },
        action: "award_warm_welcome_badge",
        service_name: "warm_welcome_badge",
        action_config: {},
        state: "active",
        enabled: true,
        next_run_at: next_friday
      )

      Rails.logger.info("ScheduledAutomations::ProcessWorker: Created warm welcome badge automation ##{automation.id}")
    rescue StandardError => e
      Rails.logger.error("ScheduledAutomations::ProcessWorker: Failed to create warm welcome automation: #{e.class} - #{e.message}")
    end

    def execute_automation(automation)
      Rails.logger.info("Executing ScheduledAutomation ##{automation.id} for user #{automation.user.username}")

      result = Executor.call(automation)

      if result.success?
        if result.article
          Rails.logger.info(
            "ScheduledAutomation ##{automation.id} succeeded: Created article ##{result.article.id} - '#{result.article.title}'"
          )
        else
          Rails.logger.info(
            "ScheduledAutomation ##{automation.id} completed: #{result.error_message}"
          )
        end
      else
        Rails.logger.error(
          "ScheduledAutomation ##{automation.id} failed: #{result.error_message}"
        )
      end
    rescue StandardError => e
      Rails.logger.error(
        "Unexpected error executing ScheduledAutomation ##{automation.id}: #{e.class} - #{e.message}"
      )
      Rails.logger.error(e.backtrace.join("\n"))
    end
  end
end

