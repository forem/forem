module ProMemberships
  # Bills pro memberships that expire today
  class Biller
    def self.call(*args)
      new(*args).call
    end

    def call
      relation = ProMembership.includes(user: [:credits]).
        where("DATE(expires_at) = ?", Time.zone.today)
      relation.find_each do |membership|
        user = membership.user
        cost = ProMembership::MONTHLY_COST

        if user.enough_credits?(cost)
          renew_membership(membership, cost)
        elsif membership.auto_recharge
          if user.stripe_id_code
            charge_user_and_renew_membership(membership, cost)
          else
            notify_admins(user, "auto recharge error: missing Stripe customer ID!")
          end
        else
          expire_membership(membership)
          notify_admins(user, "pro membership expired!")
        end
      end
    end

    private

    def renew_membership(membership, cost)
      ActiveRecord::Base.transaction do
        user = membership.user

        membership.renew!

        success = Credits::Buyer.call(
          purchaser: user,
          purchase: membership,
          cost: cost,
        )

        unless success
          notify_admins("#{user.name}'s pro membership could not be renewed with enough credits!")
          raise ActiveRecord::Rollback
        end

        chat_channel = ChatChannel.find_by(slug: "pro-members")
        if chat_channel && !chat_channel.chat_channel_memberships.exists?(user_id: user.id)
          chat_channel.add_users(user)
        end

        success
      end
    rescue StandardError => e
      Rails.logger.error(e)
      notify_admins(membership.user, "error: #{e.message}")
    end

    def expire_membership(membership)
      ActiveRecord::Base.transaction do
        user = membership.user

        membership.expire!

        chat_channel = ChatChannel.find_by(slug: "pro-members")
        chat_channel&.remove_user(user)

        user.save
      end
    rescue StandardError => e
      Rails.logger.error(e)
      notify_admins(membership.user, "error: #{e.message}")
    end

    def recharge(membership, cost)
      user = membership.user

      # charge customer for credits
      customer = Payments::Customer.get(user.stripe_id_code)
      Payments::Customer.charge(
        customer: customer,
        amount: ProMembership::MONTHLY_COST_USD,
        description: "Purchase of #{cost} credits.",
      )

      # add credits
      credits = Array.new(cost) { Credit.new(user: user, cost: 1) }
      user.credits << credits
      user.save!
    end

    def charge_user_and_renew_membership(membership, cost)
      user = membership.user
      recharge(membership, cost)
      renew_membership(membership, cost)
    rescue Payments::PaymentsError => e
      Rails.logger.error(e)
      notify_admins(user, "payment error: #{e.message}")
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error(e)
      notify_admins(user, "credits creation error: #{e.message}")
    rescue StandardError => e
      Rails.logger.error(e)
      notify_admins(user, "error: #{e.message}")
    end

    def notify_admins(user, message)
      SlackBotPingWorker.perform_async(
        message: "ProMemberships::Biller: #{user.username}: #{message}",
        channel: "pro-memberships",
        username: "pro-memberships",
        icon_emoji: ":fire:",
      )
    end
  end
end
