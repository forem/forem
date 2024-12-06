# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class PromotionCode < APIResource
    extend Stripe::APIOperations::Create
    extend Stripe::APIOperations::List
    include Stripe::APIOperations::Save

    OBJECT_NAME = "promotion_code"
  end
end
