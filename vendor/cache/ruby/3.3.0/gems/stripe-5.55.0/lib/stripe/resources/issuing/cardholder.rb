# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Issuing
    class Cardholder < APIResource
      extend Stripe::APIOperations::Create
      extend Stripe::APIOperations::List
      include Stripe::APIOperations::Save

      OBJECT_NAME = "issuing.cardholder"
    end
  end
end
