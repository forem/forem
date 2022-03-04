module Listings
  class Bump
    def self.call(listing, user:)
      new(listing, user: user).call
    end

    def initialize(listing, user:)
      @listing = listing
      @cost = listing.cost
      @user = user
    end

    def call
      @listing.purchase(@user) do |purchaser|
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
end
