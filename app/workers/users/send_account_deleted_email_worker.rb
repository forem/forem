module Users
  # The user no longer exists when this runs, so it gets the details the email
  # needs rather than the user.
  class SendAccountDeletedEmailWorker
    include Sidekiq::Job

    sidekiq_options queue: :high_priority, retry: 10

    def perform(name, email)
      NotifyMailer.with(name: name, email: email).account_deleted_email.deliver_now
    end
  end
end
