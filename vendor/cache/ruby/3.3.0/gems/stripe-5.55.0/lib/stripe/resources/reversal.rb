# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class Reversal < APIResource
    extend Stripe::APIOperations::List
    include Stripe::APIOperations::Save

    OBJECT_NAME = "transfer_reversal"

    def resource_url
      "#{Transfer.resource_url}/#{CGI.escape(transfer)}/reversals" \
      "/#{CGI.escape(id)}"
    end

    def self.update(_id, _params = nil, _opts = nil)
      raise NotImplementedError,
            "Reversals cannot be updated without a transfer ID. Update a " \
            "reversal using `r = Transfer.update_reversal('transfer_id', " \
            "'reversal_id', update_params)`"
    end

    def self.retrieve(_id, _opts = {})
      raise NotImplementedError,
            "Reversals cannot be retrieved without a transfer ID. Retrieve " \
            "a reversal using `Transfer.retrieve_reversal('transfer_id', " \
            "'reversal_id'`"
    end
  end
end
