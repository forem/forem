module Listings
  # This service wraps listing purchses in a transaction which verifies that
  # the purchaser has enough credits to complete this process.
  class Create
    # @param listing [Listing] an initialized but not yet persisted listing
    # @param purchaser [User] the user attempting to purchase the listing
    # @param cost [Integer] the number of credits the user has to spend
    # @return [Listings::Create] the service itself, used for the success? check
    def self.call(listing, purchaser:, cost:)
      new(listing, purchaser, cost).call
    end

    def initialize(listing, purchaser, cost)
      @listing = listing
      @purchaser = purchaser
      @cost = cost
      @success = false
    end

    def call
      ActiveRecord::Base.transaction do
        # Subtract credits
        enough_credits = Credits::Buy.call(
          purchaser: @purchaser,
          purchase: @listing,
          cost: @cost,
        )

        raise ActiveRecord::Rollback unless enough_credits

        # Update the listing
        @listing.bumped_at = Time.current
        @listing.published = true
        @listing.originally_published_at = Time.current

        # Since we can't raise ActiveRecord errors in this transaction
        # due to the fact that we need to display them in the :new view,
        # we manually rollback the transaction if there are validation errors
        raise ActiveRecord::Rollback unless @listing.save

        @success = true
      end
      self
    end

    def success?
      @success
    end
  end
end
