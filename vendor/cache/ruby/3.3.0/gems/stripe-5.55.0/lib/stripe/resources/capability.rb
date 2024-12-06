# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class Capability < APIResource
    extend Stripe::APIOperations::List
    include Stripe::APIOperations::Save

    OBJECT_NAME = "capability"

    def resource_url
      if !respond_to?(:account) || account.nil?
        raise NotImplementedError,
              "Capabilities cannot be accessed without an account ID."
      end
      "#{Account.resource_url}/#{CGI.escape(account)}/capabilities" \
      "/#{CGI.escape(id)}"
    end

    def self.retrieve(_id, _opts = {})
      raise NotImplementedError,
            "Capabilities cannot be retrieve without an account ID. " \
            "Retrieve a capability using Account.retrieve_capability(" \
            "'account_id', 'capability_id')`"
    end

    def self.update(_id, _params = nil, _opts = nil)
      raise NotImplementedError,
            "Capabilities cannot be updated without an account ID. Update a " \
            "capability using `Account.update_capability('account_id', " \
            "'capability_id', update_params)`"
    end
  end
end
