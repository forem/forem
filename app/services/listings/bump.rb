module Listings
  class Bump
    def self.call(listing, user:)
      new(listing, user: user).call
    end

    def initialize(listing, user:)
      @listing = listing
      @cost = listing.cost
      @user = user
      @org = Organization.find_by(id: listing.organization_id)
    end

    def call
      purchaser = [@org, @user].detect { |who| who&.enough_credits?(@cost) }
      return false unless purchaser

      charge_credits_before_bump(purchaser)
      true
    end

    private

    def charge_credits_before_bump(purchaser)
      ActiveRecord::Base.transaction do
        enough_credits = Credits::Buy.call(
          purchaser: purchaser,
          purchase: @listing,
          cost: @cost,
        )

        unless enough_credits && @listing.bump
          raise ActiveRecord::Rollback
        end
      end
    end
  end
end
