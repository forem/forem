module Credits
  class Buy
    def self.call(purchaser:, purchase:, cost:)
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
  end
end
