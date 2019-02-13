class StripeCancellationsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: :create

  def create
    verify_stripe_signature
    unsubscribe_customer
  end

  def verify_stripe_signature
    payload = request.body.read
    sig_header = request.env["HTTP_STRIPE_SIGNATURE"]

    begin
      Stripe::Webhook.construct_event(
        payload, sig_header, Rails.configuration.stripe[:stripe_cancellation_secret]
      )
    rescue JSON::ParserError
      # Invalid payload
      status 400
      return
    rescue Stripe::SignatureVerificationError
      # Invalid signature
      status 400
      return
    end
  end

  def unsubscribe_customer
    event = Stripe::Event.retrieve(params[:id])
    stripe_id = event.data.object.customer
    customer = Stripe::Customer.retrieve(stripe_id)
    monthly_dues = event.data.object.items.data[0].plan.amount
    user = User.where(stripe_id_code: stripe_id).first
    MembershipService.new(customer, user, monthly_dues).unsubscribe_customer
    render body: nil, status: 200
  rescue Stripe::APIConnectionError, Stripe::StripeError
    render body: nil, status: 400
  end
end
