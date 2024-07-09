module IncomingWebhooks
  class StripeEventsController < ApplicationController
    skip_before_action :verify_authenticity_token

    # Your Stripe CLI webhook secret for testing your endpoint locally.
    STRIPE_ENDPOINT_SECRET = Settings::General.stripe_api_key

    def create
      payload = request.body.read
      sig_header = request.env["HTTP_STRIPE_SIGNATURE"]
      event = nil

      begin
        event = Stripe::Webhook.construct_event(
          payload, sig_header, STRIPE_ENDPOINT_SECRET
        )
      rescue JSON::ParserError => e
        render json: { error: "Invalid payload (#{e.message})" }, status: :bad_request and return
      rescue Stripe::SignatureVerificationError => e
        render json: { error: "Invalid signature (#{e.message})" }, status: :bad_request and return
      end

      # Handle the event
      case event["type"]
      when "invoice.payment_succeeded"
        handle_invoice_payment_succeeded(event["data"]["object"])
      when "customer.subscription.created"
        handle_subscription_created(event["data"]["object"])
      when "customer.subscription.updated"
        handle_subscription_updated(event["data"]["object"])
      when "customer.subscription.deleted"
        handle_subscription_deleted(event["data"]["object"])
      else
        Rails.logger.info "Unhandled event type: #{event['type']}"
      end

      render json: { status: "success" }, status: :ok
    end

    private

    def handle_invoice_payment_succeeded(invoice)
      return unless invoice["metadata"].key?("user_id")

      user_id = invoice["metadata"]["user_id"]
      user = User.find_by(id: user_id)
      return unless user

      user.add_role("base_subscriber") unless user.base_subscriber?
    end

    def handle_subscription_created(subscription)
      return unless subscription["metadata"].key?("user_id")

      user_id = subscription["metadata"]["user_id"]
      user = User.find_by(id: user_id)
      return unless user

      user.add_role("base_subscriber") unless user.base_subscriber?
    end

    def handle_subscription_updated(subscription)
      return unless subscription["metadata"].key?("user_id")

      user_id = subscription["metadata"]["user_id"]
      user = User.find_by(id: user_id)
      return unless user

      user.add_role("base_subscriber") unless user.base_subscriber?
    end

    def handle_subscription_deleted(subscription)
      return unless subscription["metadata"].key?("user_id")

      user_id = subscription["metadata"]["user_id"]
      user = User.find_by(id: user_id)
      return unless user

      user.remove_role("base_subscriber")
    end
  end
end
