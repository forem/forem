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

