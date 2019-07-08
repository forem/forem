module Credits
  class Ledger
    Item = Struct.new(:purchase, :cost, :purchased_at, keyword_init: true)

    def initialize(user)
      @user = user
    end

    def self.call(*args)
      new(*args).call
    end

    def call
      # build the ledger for the user
      ledger = {
        [User.name, user.id] => build_ledger_for(user.credits)
      }

      # build the ledger for the organizations the user is an admin at
      user.admin_organizations.find_each do |org|
        ledger[[Organization.name, org.id]] = build_ledger_for(org.credits)
      end

      ledger
    end

    private

    attr_reader :user

    def purchaseable
      %w[ClassifiedListing]
    end

    def load_purchases(credits)
      credits.spent.select(
        :purchase_id,
        :purchase_type,
        Arel.sql("COUNT(*)").as("cost"),
        Arel.sql("MAX(spent_at)").as("purchased_at"),
      ).group(:purchase_id, :purchase_type).order(purchased_at: :desc)
    end

    def build_ledger_for(credits)
      purchases = load_purchases(credits)
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
      if unassociated_purchase
        items << Item.new(cost: unassociated_purchase.cost.to_i)
      end

      items
    end
  end
end
