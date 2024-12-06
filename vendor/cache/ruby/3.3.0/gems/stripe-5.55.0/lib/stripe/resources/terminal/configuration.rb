# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Terminal
    class Configuration < APIResource
      extend Stripe::APIOperations::Create
      include Stripe::APIOperations::Delete
      extend Stripe::APIOperations::List
      include Stripe::APIOperations::Save

      OBJECT_NAME = "terminal.configuration"
    end
  end
end
