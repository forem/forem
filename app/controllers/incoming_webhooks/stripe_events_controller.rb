module IncomingWebhooks
  class StripeEventsController < ApplicationController
    skip_before_action :verify_authenticity_token

    PAID_PAYMENT_STATUSES = %w[paid no_payment_required].freeze
    ACTIVE_SUBSCRIPTION_STATUSES = %w[active trialing].freeze

    def create
      endpoint_secret = stripe_endpoint_secret
      if endpoint_secret.blank?
        Rails.logger.error "Stripe webhook signing secret is not configured"
        render json: { error: "Webhook signing secret is not configured" }, status: :service_unavailable and return
      end

      payload = request.body.read
      sig_header = request.env["HTTP_STRIPE_SIGNATURE"]
      if sig_header.blank?
        render json: { error: "Missing signature header" }, status: :bad_request and return
      end

      begin
        event = Stripe::Webhook.construct_event(
          payload, sig_header, endpoint_secret
        )
      rescue JSON::ParserError
        Rails.logger.error "Stripe webhook rejected: invalid payload"
        render json: { error: "Invalid payload" }, status: :bad_request and return
      rescue Stripe::SignatureVerificationError
        Rails.logger.error "Stripe webhook rejected: invalid signature"
        render json: { error: "Invalid signature" }, status: :bad_request and return
      end

      case event["type"]
      when "checkout.session.completed", "checkout.session.async_payment_succeeded"
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

    def stripe_endpoint_secret
      ApplicationConfig["STRIPE_SIGNING_SECRET"]
    end

    def handle_checkout_session_completed(invoice)
      return unless paid_checkout_session?(invoice)

      # This is the one we're using to verify completion
      user_id = extract_metadata(invoice)&.[]("user_id")
      return unless user_id

      user = User.find_by(id: user_id)
      return unless user

      unless user.base_subscriber? # Don't add role if user is already a subscriber
        user.add_role("base_subscriber")
        user.stripe_id_code = extract_customer(invoice)
        # We assume checkout completion for a subscription starts it as paying for now
        # unless it was a trial.
        is_trial = invoice["subscription_data"]&.[]("trial_period_days")
        user.current_subscriber_status = is_trial ? :trial_subscription : :paying_subscription
        user.save
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
                              user_agent: event.user_agent,
                              context_type: event.context_type,
                              billboard_id: event.billboard_id)
      end
    end

    def handle_subscription_created(subscription)
      # This can likely be deleted.
      user_id = extract_metadata(subscription)&.[]("user_id")
      return unless user_id

      user = User.find_by(id: user_id)
      return unless user

      if active_subscription_status?(subscription["status"]) && !user.base_subscriber?
        user.add_role("base_subscriber")
      end
      user.update(current_subscriber_status: determine_subscriber_status(subscription))
    end

    def handle_subscription_updated(subscription)
      metadata = extract_metadata(subscription)
      user_id = metadata&.[]("user_id")
      return unless user_id

      user = User.find_by(id: user_id)
      return unless user

      if cancel_at_period_end?(subscription, metadata)
        user.add_role("impending_base_subscriber_cancellation") unless user.impending_base_subscriber_cancellation?
      elsif active_subscription_status?(subscription["status"])
        user.add_role("base_subscriber") unless user.base_subscriber?
      end
      user.update(current_subscriber_status: determine_subscriber_status(subscription))
    end

    def handle_subscription_deleted(subscription)
      user_id = extract_metadata(subscription)&.[]("user_id")
      return unless user_id

      user = User.find_by(id: user_id)
      return unless user

      user.add_role("impending_base_subscriber_cancellation") unless user.impending_base_subscriber_cancellation?
      user.update(current_subscriber_status: :not_subscribed)
    end

    def paid_checkout_session?(invoice)
      PAID_PAYMENT_STATUSES.include?(invoice["payment_status"])
    end

    def active_subscription_status?(status)
      ACTIVE_SUBSCRIPTION_STATUSES.include?(status)
    end

    def cancel_at_period_end?(subscription, metadata)
      subscription["cancel_at_period_end"] == true || metadata&.[]("cancel_at_period_end") == true
    end

    def extract_metadata(obj)
      return obj.metadata if obj.respond_to?(:metadata)
      return obj["metadata"] if obj.is_a?(Hash) && obj.key?("metadata")

      nil
    end

    def extract_customer(obj)
      return obj.customer if obj.respond_to?(:customer)
      return obj["customer"] if obj.is_a?(Hash) && obj.key?("customer")

      nil
    rescue StandardError => e
      Rails.error.report(e, context: { object_class: obj.class.name })
      nil
    end

    def determine_subscriber_status(subscription)
      case subscription["status"]
      when "trialing"
        :trial_subscription
      when "active"
        # If price is 0, it's free. Stripe subscription items have prices.
        # This is a bit deep, so we'll look for 0 price in the first item.
        price = subscription["items"]["data"][0]["price"] if subscription["items"] && subscription["items"]["data"]
        price && price["unit_amount"].zero? ? :free_subscription : :paying_subscription
      else
        :not_subscribed
      end
    end
  end
end
