# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class ApplicationFeeRefund < APIResource
    extend Stripe::APIOperations::List
    include Stripe::APIOperations::Save

    OBJECT_NAME = "fee_refund"

    def resource_url
      "#{ApplicationFee.resource_url}/#{CGI.escape(fee)}/refunds" \
      "/#{CGI.escape(id)}"
    end

    def self.update(_id, _params = nil, _opts = nil)
      raise NotImplementedError,
            "Application fee refunds cannot be updated without an " \
            "application fee ID. Update an application fee refund using " \
            "`ApplicationFee.update_refund('fee_id', 'refund_id', " \
            "update_params)`"
    end

    def self.retrieve(_id, _api_key = nil)
      raise NotImplementedError,
            "Application fee refunds cannot be retrieved without an " \
            "application fee ID. Retrieve an application fee refund using " \
            "`ApplicationFee.retrieve_refund('fee_id', 'refund_id')`"
    end
  end
end
