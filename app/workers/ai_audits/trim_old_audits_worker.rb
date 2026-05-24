module AiAudits
  class TrimOldAuditsWorker
    include Sidekiq::Job

    sidekiq_options queue: :low_priority, retry: 5

    def perform
      AiAudit.fast_trim_old_audits
    end
  end
end
