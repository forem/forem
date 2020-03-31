module ProMemberships
  # Notifies Pro members with insufficient credits of the impeding expiration
  class ExpirationNotifier
    def initialize(expiration_date)
      @expiration_date = expiration_date
    end

    def self.call(*args)
      new(*args).call
    end

    def call
      count = 0

      # NOTE: naive implementation because this is supposed to be called every 24hrs
      relation = ProMembership.
        includes(user: [:credits]).
        where("DATE(expires_at) = ?", expiration_date).
        where(auto_recharge: false)
      relation.find_each do |membership|
        next if membership.user.enough_credits?(ProMembership::MONTHLY_COST)

        # NOTE: maybe we should "deliver_later" and update the flags there
        ProMembershipMailer.expiring_membership(membership, expiration_date).deliver_now

        membership.expiration_notification_at = Time.current
        membership.increment(:expiration_notifications_count)
        membership.save!

        SlackBotPingWorker.perform_async(
          message: "#{membership.user.name}'s pro membership expires on #{expiration_date}",
          channel: "pro-memberships",
          username: "pro-memberships",
          icon_emoji: ":fire:",
        )

        count += 1
      end

      count
    end

    private

    attr_reader :expiration_date
  end
end
