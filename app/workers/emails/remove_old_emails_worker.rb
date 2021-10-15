module Emails
  class RemoveOldEmailsWorker
    include Sidekiq::Worker

    sidekiq_options queue: :low_priority, retry: 10

    STATEMENT_TIMEOUT = ENV.fetch("STATEMENT_TIMEOUT_REMOVE_OLD_EMAILS", 10).to_i.seconds

    def perform
      EmailMessage.with_statement_timeout STATEMENT_TIMEOUT do
        EmailMessage.fast_destroy_old_retained_email_deliveries
      end
    end
  end
end
