# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class FileLink < APIResource
    extend Stripe::APIOperations::Create
    extend Stripe::APIOperations::List
    include Stripe::APIOperations::Save

    OBJECT_NAME = "file_link"
  end
end
