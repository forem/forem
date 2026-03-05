module AgentSessions
  class CleanupExpiredRawFilesWorker
    include Sidekiq::Job

    sidekiq_options queue: :low_priority, retry: 3

    BATCH_SIZE = 100

    def perform
      return unless AgentSessions::S3Storage.enabled?

      expired_sessions.find_each(batch_size: BATCH_SIZE) do |session|
        AgentSessions::S3Storage.delete(session.s3_key)
        session.update_column(:s3_key, nil)
      rescue StandardError => e
        Rails.logger.warn(
          "AgentSessions::CleanupExpiredRawFilesWorker failed for session #{session.id}: #{e.message}",
        )
      end
    end

    private

    def expired_sessions
      AgentSession
        .where.not(s3_key: nil)
        .where(created_at: ...AgentSession::RAW_FILE_RETENTION_DAYS.days.ago)
    end
  end
end
