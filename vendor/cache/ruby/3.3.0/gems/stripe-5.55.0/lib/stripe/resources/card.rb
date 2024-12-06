# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class Card < APIResource
    include Stripe::APIOperations::Delete
    extend Stripe::APIOperations::List
    include Stripe::APIOperations::Save

    OBJECT_NAME = "card"

    def resource_url
      if respond_to?(:recipient) && !recipient.nil? && !recipient.empty?
        "#{Recipient.resource_url}/#{CGI.escape(recipient)}/cards/#{CGI.escape(id)}"
      elsif respond_to?(:customer) && !customer.nil? && !customer.empty?
        "#{Customer.resource_url}/#{CGI.escape(customer)}/sources/#{CGI.escape(id)}"
      elsif respond_to?(:account) && !account.nil? && !account.empty?
        "#{Account.resource_url}/#{CGI.escape(account)}/external_accounts/#{CGI.escape(id)}"
      end
    end

    def self.update(_id, _params = nil, _opts = nil)
      raise NotImplementedError,
            "Card cannot be updated without a customer ID or an account ID. " \
            "Update a card using `Customer.update_source('customer_id', " \
            "'card_id', update_params)` or `Account.update_external_account(" \
            "'account_id', 'card_id', update_params)`"
    end

    def self.retrieve(_id, _opts = nil)
      raise NotImplementedError,
            "Card cannot be retrieved without a customer ID or an account " \
            "ID. Retrieve a card using `Customer.retrieve_source(" \
            "'customer_id', 'card_id')` or " \
            "`Account.retrieve_external_account('account_id', 'card_id')`"
    end
  end
end
