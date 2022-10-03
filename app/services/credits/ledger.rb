module Credits
  class Ledger
    Item = Struct.new(:purchase, :cost, :purchased_at, keyword_init: true)

    def initialize(user)
      @user = user
    end

    def self.call(...)
      new(...).call
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
      %w[Listing]
    end

    def load_credits_purchases(credits)
      credits.spent.select(
        :purchase_id,
        :purchase_type,
        Arel.sql("COUNT(*)").as("cost"),
        Arel.sql("MAX(spent_at)").as("purchased_at"),
      ).group(:purchase_id, :purchase_type).order(purchased_at: :desc)
    end

    def build_ledger_for(credits)
      credits_purchases = load_credits_purchases(credits)
      credits_purchases_with_purchase = credits_purchases.select(&:purchase_type)
      credits_purchases_without_purchase = credits_purchases.reject(&:purchase_type)
      items = []

      if credits_purchases_with_purchase.present?
        # to avoid N+1 on purchases, we load them by type separately
        purchase_types = credits_purchases_with_purchase.filter_map(&:purchase_type).uniq
        purchase_types.each do |purchase_type|
          credits_purchases_by_type = credits_purchases_with_purchase.select do |row|
            row.purchase_type == purchase_type
          end

          next unless purchase_type.constantize

          purchase_set = purchase_type.constantize.where(id: credits_purchases_by_type.map(&:purchase_id))
          credits_purchases_by_type.each do |credit_purchase|
            purchase = purchase_set.detect { |set| set.id == credit_purchase.purchase_id }
            items << Item.new(
              purchase: purchase,
              cost: credit_purchase.cost.to_i,
              purchased_at: credit_purchase.purchased_at,
            )
          end
        end
      end

      # add items without a purchase association lumped at the bottom
      if credits_purchases_without_purchase.present?
        total_cost = credits_purchases_without_purchase.sum(&:cost)
        items << Item.new(cost: total_cost.to_i)
      end

      items
    end
  end
end
