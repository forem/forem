module Credits
  class Buyer
    def initialize(purchaser:, purchase:, cost:)
      @purchaser = purchaser
      @purchase = purchase
      @cost = cost
    end

    def self.call(*args)
      new(*args).call
    end

    def call
      return false unless has_available_credits?

      purchaser.credits.unspent.limit(cost).update_all(
        spent: true,
        spent_at: Time.current,
        purchase_type: purchase.class.name,
        purchase_id: purchase.id,
      )
      true
    end

    private

    attr_reader :purchaser, :purchase, :cost

    def has_available_credits?
      purchaser.credits.unspent.size >= cost
    end
  end
end
