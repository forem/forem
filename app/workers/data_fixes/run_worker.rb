module DataFixes
  class RunWorker
    include Sidekiq::Job
    sidekiq_options queue: :high_priority, retry: 5

    def perform(fix_key, requested_by_user_id = nil)
      Runner.call(fix_key)

      Rails.logger.info(
        "time=#{Time.current.rfc3339}, data_fix=#{fix_key}, requested_by_user_id=#{requested_by_user_id}, status=succeeded",
      )
    rescue StandardError => e
      Rails.logger.error(
        "time=#{Time.current.rfc3339}, data_fix=#{fix_key}, requested_by_user_id=#{requested_by_user_id}, status=failed",
      )

      Honeybadger.notify(e, context: { data_fix: fix_key, requested_by_user_id: requested_by_user_id })
      raise
    end
  end
end
