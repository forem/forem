# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Identity
    class VerificationSession < APIResource
      extend Stripe::APIOperations::Create
      extend Stripe::APIOperations::List
      include Stripe::APIOperations::Save

      OBJECT_NAME = "identity.verification_session"

      custom_method :cancel, http_verb: :post
      custom_method :redact, http_verb: :post

      def cancel(params = {}, opts = {})
        request_stripe_object(
          method: :post,
          path: resource_url + "/cancel",
          params: params,
          opts: opts
        )
      end

      def redact(params = {}, opts = {})
        request_stripe_object(
          method: :post,
          path: resource_url + "/redact",
          params: params,
          opts: opts
        )
      end
    end
  end
end
