# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Terminal
    class Reader < APIResource
      extend Stripe::APIOperations::Create
      include Stripe::APIOperations::Delete
      extend Stripe::APIOperations::List
      include Stripe::APIOperations::Save

      OBJECT_NAME = "terminal.reader"

      custom_method :cancel_action, http_verb: :post
      custom_method :process_payment_intent, http_verb: :post
      custom_method :process_setup_intent, http_verb: :post
      custom_method :set_reader_display, http_verb: :post

      def cancel_action(params = {}, opts = {})
        request_stripe_object(
          method: :post,
          path: resource_url + "/cancel_action",
          params: params,
          opts: opts
        )
      end

      def process_payment_intent(params = {}, opts = {})
        request_stripe_object(
          method: :post,
          path: resource_url + "/process_payment_intent",
          params: params,
          opts: opts
        )
      end

      def process_setup_intent(params = {}, opts = {})
        request_stripe_object(
          method: :post,
          path: resource_url + "/process_setup_intent",
          params: params,
          opts: opts
        )
      end

      def set_reader_display(params = {}, opts = {})
        request_stripe_object(
          method: :post,
          path: resource_url + "/set_reader_display",
          params: params,
          opts: opts
        )
      end

      def test_helpers
        TestHelpers.new(self)
      end

      class TestHelpers < APIResourceTestHelpers
        RESOURCE_CLASS = Reader

        custom_method :present_payment_method, http_verb: :post

        def present_payment_method(params = {}, opts = {})
          @resource.request_stripe_object(
            method: :post,
            path: resource_url + "/present_payment_method",
            params: params,
            opts: opts
          )
        end
      end
    end
  end
end
