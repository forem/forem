# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Issuing
    class Transaction < APIResource
      extend Stripe::APIOperations::List
      include Stripe::APIOperations::Save

      OBJECT_NAME = "issuing.transaction"
    end
  end
end
