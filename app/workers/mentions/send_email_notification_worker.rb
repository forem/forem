module Mentions
  class SendEmailNotificationWorker
    include Sidekiq::Job
    sidekiq_options queue: :default, retry: 10

    # Sends an email notification for a mention unless the author is spam/suspended
    # or the mentionable has a negative score or an active spam reaction.
    def perform(mention_id)
      mention = Mention.find_by(id: mention_id)
      return unless mention

      mentionable = mention.mentionable
      return unless mentionable
      return if mentionable.user&.spam_or_suspended?
      return if mentionable.respond_to?(:score) && mentionable.score.to_i.negative?
      return if Spam::Handler.active_spam_reaction_for?(reactable: mentionable)

      NotifyMailer.with(mention: mention).new_mention_email.deliver_now
    end
  end
end
