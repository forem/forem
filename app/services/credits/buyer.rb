module Credits
  class Buyer
    def initialize(purchaser:, purchase:, cost:)
      @purchaser = purchaser
      @purchase = purchase
      @cost = cost
    end

    def self.call(...)
      new(...).call
    end

    def call
      return false unless purchaser.enough_credits?(cost)

      purchaser.credits.unspent.limit(cost).update_all(
        spent: true,
        spent_at: Time.current,
        purchase_type: purchase.class.name,
        purchase_id: purchase.id,
      )
      purchaser.save

      true
    end

    private

    attr_reader :purchaser, :purchase, :cost
  end
end
