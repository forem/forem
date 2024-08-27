class StripeSubscriptionsController < ApplicationController
  before_action :authenticate_user!

  def new
    Stripe.api_key = Settings::General.stripe_api_key

    item_code = if ENV.fetch("STRIPE_TAG_MODERATOR_ITEM_CODE", nil).present? && current_user&.tag_moderator?
                  ENV.fetch("STRIPE_TAG_MODERATOR_ITEM_CODE", nil)
                elsif params[:item].present? && params[:item] != ENV.fetch("STRIPE_TAG_MODERATOR_ITEM_CODE", nil)
                  params[:item]
                else
                  ENV.fetch("STRIPE_BASE_ITEM_CODE", nil)
                end

    session = Stripe::Checkout::Session.create(
      line_items: [
        {
          price: item_code,
          quantity: 1
        },
      ],
      mode: params[:mode] || "subscription",
      success_url: URL.url(ENV["SUBSCRIPTION_SUCCESS_URL"] || "/settings/billing"),
      cancel_url: URL.url(ENV["SUBSCRIPTION_CANCEL_URL"] || "/settings/billing"),
      consent_collection: {
        terms_of_service: "required"
      },
      customer_email: current_user.email,
      metadata: {
        user_id: current_user.id
      },
    )
    redirect_to session.url, allow_other_host: true
  end
end
