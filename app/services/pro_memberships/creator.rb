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
        channel = ChatChannel.find_by(slug: "pro-members")
        channel&.add_users(user)

        true
      else
        false
      end
    end

    private

    attr_reader :user

    def purchase_pro_membership
      cost = ProMembership::MONTHLY_COST
      return false unless user.enough_credits?(cost)

      ActiveRecord::Base.transaction do
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
