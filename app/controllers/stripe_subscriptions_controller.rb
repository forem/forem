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

  def destroy
    if params[:verification] == "pleasecancelmyplusplus" && current_user.stripe_id_code.present?
      Stripe.api_key = Settings::General.stripe_api_key

      # Find the Stripe subscription associated with the user
      subscription = Stripe::Subscription.list(customer: current_user.stripe_id_code).data.first

      if subscription.present?
        # Cancel the subscription immediately
        Stripe::Subscription.update(subscription.id, {
                                      cancel_at_period_end: false
                                    })
        current_user.remove_role("base_subscriber")
        current_user.touch
        current_user.profile&.touch
        flash[:notice] = "Your subscription has been canceled."
      else
        flash[:alert] = "No active subscription found."
      end
    elsif current_user.stripe_id_code.present?
      flash[:alert] = "Invalid verification parameter. Subscription was not canceled."
    else
      flash[:alert] = "No active subscription found. Please contact us if you believe this is an error."
    end

    redirect_to user_settings_path(current_user)
  end
end
