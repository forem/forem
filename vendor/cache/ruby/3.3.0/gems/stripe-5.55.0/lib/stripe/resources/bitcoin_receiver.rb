# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  # Directly creating or retrieving BitcoinReceivers is deprecated. Please use
  # the Sources API instead: https://stripe.com/docs/sources/bitcoin
  class BitcoinReceiver < APIResource
    extend Stripe::APIOperations::List

    OBJECT_NAME = "bitcoin_receiver"

    def self.resource_url
      "/v1/bitcoin/receivers"
    end

    def resource_url
      if respond_to?(:customer) && !customer.nil? && customer != ""
        "#{Customer.resource_url}/#{CGI.escape(customer)}/sources/#{CGI.escape(id)}"
      else
        "#{self.class.resource_url}/#{CGI.escape(id)}"
      end
    end
  end
end
