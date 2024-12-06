# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class Coupon < APIResource
    extend Stripe::APIOperations::Create
    include Stripe::APIOperations::Delete
    extend Stripe::APIOperations::List
    include Stripe::APIOperations::Save

    OBJECT_NAME = "coupon"
  end
end
