# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  # Directly retrieving BitcoinTransactions is deprecated. Please use
  # the Sources API instead: https://stripe.com/docs/sources/bitcoin
  class BitcoinTransaction < APIResource
    extend Stripe::APIOperations::List

    OBJECT_NAME = "bitcoin_transaction"

    def self.resource_url
      "/v1/bitcoin/transactions"
    end
  end
end
