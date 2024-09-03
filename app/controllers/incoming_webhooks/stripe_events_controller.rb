module IncomingWebhooks
  class StripeEventsController < ApplicationController
    skip_before_action :verify_authenticity_token

    STRIPE_ENDPOINT_SECRET = ApplicationConfig["STRIPE_SIGNING_SECRET"]

    def create
      payload = request.body.read
      sig_header = request.env["HTTP_STRIPE_SIGNATURE"]
      event = nil

      Rails.logger.info "Request Headers: #{request.headers.to_h.inspect}"
      Rails.logger.info "Payload: #{payload}"
      Rails.logger.info "Signature Header: #{sig_header}"
      Rails.logger.info "Stripe Endpoint Secret: #{STRIPE_ENDPOINT_SECRET}"

      begin
        event = Stripe::Webhook.construct_event(
          payload, sig_header, STRIPE_ENDPOINT_SECRET
        )
      rescue JSON::ParserError => e
        Rails.logger.error "JSON::ParserError: #{e.message}"
        render json: { error: "Invalid payload (#{e.message})" }, status: :bad_request and return
      rescue Stripe::SignatureVerificationError => e
        Rails.logger.error "Stripe::SignatureVerificationError: #{e.message}"
        render json: { error: "Invalid signature (#{e.message})" }, status: :bad_request and return
      end

      Rails.logger.info "Event: #{event.inspect}"
      Rails.logger.info "Event Data: #{event['data'].inspect}"

      case event["type"]
      when "checkout.session.completed"
        handle_checkout_session_completed(event["data"]["object"])
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

    def handle_checkout_session_completed(invoice)
      # This is the one we're using to verify completion
      metadata = extract_metadata(invoice)
      return unless metadata["user_id"]

      user_id = metadata["user_id"]
      user = User.find_by(id: user_id)
      return unless user

      unless user.base_subscriber? # Don't add role if user is already a subscriber
        user.add_role("base_subscriber")
        user.stripe_id_code = extract_customer(invoice)
        user.touch
        user.profile&.touch
        NotifyMailer.with(user: user).base_subscriber_role_email.deliver_now
      end

      last_billboard_events = BillboardEvent
        .where(user_id: user.id, category: "click")
        .where("created_at > ?", 3.hours.ago).order("created_at DESC").limit(3)
      return unless last_billboard_events.any?

      last_billboard_events.each do |event|
        BillboardEvent.create(user_id: user.id,
                              category: "conversion",
                              geolocation: event.geolocation,
                              context_type: event.context_type,
                              billboard_id: event.billboard_id)
      end
    end

    def handle_subscription_created(subscription)
      # This can likely be deleted.
      metadata = extract_metadata(subscription)
      return unless metadata["user_id"]

      user_id = metadata["user_id"]
      user = User.find_by(id: user_id)
      return unless user

      user.add_role("base_subscriber") unless user.base_subscriber?
    end

    def handle_subscription_updated(subscription)
      metadata = extract_metadata(subscription)
      return unless metadata["user_id"]

      user_id = metadata["user_id"]
      user = User.find_by(id: user_id)
      return unless user

      user.add_role("base_subscriber") unless user.base_subscriber?
    end

    def handle_subscription_deleted(subscription)
      metadata = extract_metadata(subscription)
      return unless metadata["user_id"]

      user_id = metadata["user_id"]
      user = User.find_by(id: user_id)
      return unless user

      user.remove_role("base_subscriber")
      user.touch
      user.profile&.touch
    end

    def extract_metadata(obj)
      return obj.metadata if obj.respond_to?(:metadata)
      return obj["metadata"] if obj.is_a?(Hash) && obj.key?("metadata")

      nil
    end

    def extract_customer(obj)
      obj.customer if obj.respond_to?(:customer)
    rescue StandardError
      nil
    end
  end
end
