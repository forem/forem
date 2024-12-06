# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class FundingInstructions < APIResource
    OBJECT_NAME = "funding_instructions"

    def resource_url
      if !respond_to?(:customer) || customer.nil?
        raise NotImplementedError,
              "FundingInstructions cannot be accessed without a customer ID."
      end
      "#{Customer.resource_url}/#{CGI.escape(customer)}/funding_instructions" "/#{CGI.escape(id)}"
    end
  end
end
