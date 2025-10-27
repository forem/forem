module Spam
  class BlockDomainAndSuspendUsersWorker
    include Sidekiq::Worker

    sidekiq_options queue: :default, retry: 5

    # @param email_domain [String]
    def perform(email_domain)
      return if email_domain.blank?

      domain = email_domain.downcase.strip

      # Prevent concurrent executions for the same domain
      lock_key = "spam:block_domain_and_suspend:#{domain}"
      locked = Sidekiq.redis { |r| r.set(lock_key, 1, nx: true, ex: 300) }
      return unless locked

      begin
        BlockedEmailDomain.find_or_create_by(domain: domain)

        User.where("email LIKE ?", "%@#{domain}").find_each do |user|
          next if user.spam? || user.suspended?

          user.add_role(:suspended)

          Note.create(
            author_id: Settings::General.mascot_user_id,
            noteable: user,
            reason: "automatic_suspend",
            content: "Automatically suspended due to spam patterns detected from email domain #{domain}",
          )
        end

        Rails.logger.info("Blocked email domain #{domain} and suspended users with that domain")
      ensure
        Sidekiq.redis { |r| r.del(lock_key) }
      end
    end
  end
end


