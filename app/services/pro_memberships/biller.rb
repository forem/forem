module ProMemberships
  # Bills pro memberships that expire today
  class Biller
    def self.call(*args)
      new(*args).call
    end

    def call
      relation = ProMembership.includes(user: [:credits]).where("DATE(expires_at) = ?", Time.zone.today)
      relation.find_each do |membership|
        user = membership.user
        cost = ProMembership::MONTHLY_COST

        if user.has_enough_credits?(cost)
          renewed = renew_membership(membership, cost)
          unless renewed
            # TODO: notify admins that something went wrong
          end
        elsif membership.auto_recharge
          # TODO: add Stripe code to charge and then buy membership
        else
          membership.expire!
        end
      end
    end

    private

    def renew_membership(membership, cost)
      ActiveRecord::Base.transaction do
        membership.renew!

        Credits::Buyer.call(
          purchaser: membership.user,
          purchase: membership,
          cost: cost,
        )
      end
    end
  end
end
