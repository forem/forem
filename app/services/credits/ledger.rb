module Credits
  class Ledger
    Item = Struct.new(:purchase, :cost, :purchased_at, keyword_init: true)

    def initialize(owner)
      @owner = owner
    end

    def self.call(*args)
      new(*args).call
    end

    def call
      purchases = load_purchases

      items = []

      # to avoid N+1 on purchases, we load them by type separately
      listings_purchases = purchases.select { |row| row.purchase_type == "ClassifiedListing" }
      listings = ClassifiedListing.where(id: listings_purchases.map(&:purchase_id))
      listings_purchases.each do |purchase|
        listing = listings.select { |l| l.id == purchase.purchase_id }.first
        items << Item.new(
          purchase: listing,
          cost: purchase.cost.to_i,
          purchased_at: purchase.purchased_at,
        )
      end

      # add items without a purchase association at the bottom
      unassociated_purchase = purchases.reject(&:purchase_type).first
      items << Item.new(cost: unassociated_purchase.cost.to_i)

      items
    end

    private

    attr_reader :owner

    def purchaseable
      %w[ClassifiedListing]
    end

    def load_purchases
      owner.credits.spent.select(
        :purchase_id,
        :purchase_type,
        Arel.sql("COUNT(*)").as("cost"),
        Arel.sql("MAX(spent_at)").as("purchased_at"),
      ).group(:purchase_id, :purchase_type).order(purchased_at: :desc)
    end
  end
end
