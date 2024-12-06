# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class CustomerBalanceTransaction < APIResource
    extend Stripe::APIOperations::List
    include Stripe::APIOperations::Save

    OBJECT_NAME = "customer_balance_transaction"

    def resource_url
      if !respond_to?(:customer) || customer.nil?
        raise NotImplementedError,
              "Customer Balance Transactions cannot be accessed without a customer ID."
      end
      "#{Customer.resource_url}/#{CGI.escape(customer)}/balance_transactions/#{CGI.escape(id)}"
    end

    def self.retrieve(_id, _opts = {})
      raise NotImplementedError,
            "Customer Balance Transactions cannot be retrieved without a customer ID. " \
            "Retrieve a Customer Balance Transaction using `Customer.retrieve_balance_transaction('cus_123', 'cbtxn_123')`"
    end

    def self.update(_id, _params = nil, _opts = nil)
      raise NotImplementedError,
            "Customer Balance Transactions cannot be retrieved without a customer ID. " \
            "Update a Customer Balance Transaction using `Customer.update_balance_transaction('cus_123', 'cbtxn_123', params)`"
    end
  end
end
