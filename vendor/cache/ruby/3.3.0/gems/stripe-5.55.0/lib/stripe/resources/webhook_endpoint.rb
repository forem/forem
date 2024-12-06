# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class WebhookEndpoint < APIResource
    extend Stripe::APIOperations::Create
    include Stripe::APIOperations::Delete
    extend Stripe::APIOperations::List
    include Stripe::APIOperations::Save

    OBJECT_NAME = "webhook_endpoint"
  end
end
