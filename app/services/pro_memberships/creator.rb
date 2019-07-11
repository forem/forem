module ProMemberships
  class Creator
    def initialize(user)
      @user = user
    end

    def self.call(*args)
      new(*args).call
    end

    def call
      if purchase_pro_membership
        ProMemberships::PopulateHistoryJob.perform_later(user.id)
        true
      else
        false
      end
    end

    private

    attr_reader :user

    def purchase_pro_membership
      cost = ProMembership::MONTHLY_COST

      ActiveRecord::Base.transaction do
        raise ActiveRecord::Rollback if user.credits.unspent.size < cost

        pro_membership = ProMembership.create!(user: user)
        Credits::Buyer.call(
          purchaser: user,
          purchase: pro_membership,
          cost: cost,
        )
      end
    end
  end
end
