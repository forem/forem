class StripeActiveCardsController < ApplicationController
  before_action :authenticate_user!
  before_action :touch_current_user

  def create
    authorize :stripe_active_card

    customer = find_or_create_customer

    if Payments::Customer.create_source(customer.id, stripe_params[:stripe_token])
      Rails.logger.info("Stripe Add New Card Success - #{current_user.username}")
      flash[:settings_notice] = "Your billing information has been updated"
    else
      DatadogStatsClient.increment("stripe.errors", tags: ["action:create_card", "user_id:#{current_user.id}"])

      Rails.logger.error("Stripe Add New Card Failure - #{current_user.username}")
      flash[:error] = "There was a problem updating your billing info."
    end
    redirect_to user_settings_path(:billing)
  rescue Payments::CardError, Payments::InvalidRequestError => e
    DatadogStatsClient.increment("stripe.errors", tags: ["action:create_card", "user_id:#{current_user.id}"])
    redirect_to user_settings_path(:billing), flash: { error: e.message }
  end

  def update
    authorize :stripe_active_card

    # change the default card
    customer = find_customer
    card = Payments::Customer.get_source(customer, params[:id])
    customer.default_source = card.id

    if Payments::Customer.save(customer)
      Rails.logger.info("Stripe Card Update Success - #{current_user.username}")
      flash[:settings_notice] = "Your billing information has been updated"
    else
      DatadogStatsClient.increment("stripe.errors", tags: ["action:update_card", "user_id:#{current_user.id}"])

      Rails.logger.error("Stripe Card Update Failure - #{current_user.username}")
      flash[:error] = "There was a problem updating your billing info."
    end

    redirect_to user_settings_path(:billing)
  rescue Payments::CardError, Payments::InvalidRequestError => e
    DatadogStatsClient.increment("stripe.errors", tags: ["action:update_card", "user_id:#{current_user.id}"])

    redirect_to user_settings_path(:billing), flash: { error: e.message }
  end

  def destroy
    authorize :stripe_active_card

    customer = find_customer

    if customer.subscriptions.count.positive?
      flash[:error] = "Can't remove card if you have an active membership. Please cancel your membership first."
    else
      source = Payments::Customer.get_source(customer, params[:id])
      Payments::Customer.detach_source(customer.id, source.id)
      Payments::Customer.save(customer)

      flash[:settings_notice] = "Your card has been successfully removed."
    end

    redirect_to user_settings_path(:billing)
  rescue Payments::InvalidRequestError => e
    DatadogStatsClient.increment("stripe.errors")

    redirect_to user_settings_path(:billing), flash: { error: e.message }
  end

  private

  def find_customer
    Payments::Customer.get(current_user.stripe_id_code)
  end

  def find_or_create_customer
    if current_user.stripe_id_code.present?
      find_customer
    else
      Payments::Customer.create(email: current_user.email).tap do |customer|
        current_user.update(stripe_id_code: customer.id)
      end
    end
  end

  def stripe_params
    params.permit(%i[stripe_token])
  end
end
