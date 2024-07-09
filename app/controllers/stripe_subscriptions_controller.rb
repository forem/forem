class StripeSubscriptionsController < ApplicationController
  def new
    Stripe.api_key = Settings::General.stripe_api_key
    session = Stripe::Checkout::Session.create(
      line_items: [
        {
          price: params[:item] || ENV.fetch("STRIPE_BASE_ITEM_CODE", nil),
          quantity: 1
        },
      ],
      mode: params[:mode] || "subscription",
      success_url: URL.url(ENV["SUBSCRIPTION_SUCCESS_URL"] || "/settings/billing"),
      cancel_url: URL.url("/settings/billing"),
      customer_email: current_user.email,
      metadata: {
        user_id: current_user.id
      },
    )
    redirect_to session.url, allow_other_host: true
  end
end
