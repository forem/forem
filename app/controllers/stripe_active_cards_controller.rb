class StripeActiveCardsController < ApplicationController
  before_action :authenticate_user!
  before_action :touch_current_user

  def create
    authorize :stripe_active_card
    customer = find_or_create_customer
    if customer.sources.create(source: stripe_params[:stripe_token])
      logger.info("Stripe Add New Card Success - #{current_user.username}")
      redirect_to "/settings/billing", notice:
        "Your billing information has been updated"
    else
      logger.info("Stripe Add New Card Failure - #{current_user.username}")
      redirect_to "/settings/billing", flash: { error:
        "There was a problem updating your billing info." }
    end
  end

  def update
    authorize :stripe_active_card
    customer = Stripe::Customer.retrieve(current_user.stripe_id_code)
    card = customer.sources.retrieve(params[:id])
    customer.default_source = card.id
    if customer.save
      logger.info("Stripe Card Update Success - #{current_user.username}")
      redirect_to "/settings/billing", notice:
        "Your billing information has been updated"
    else
      logger.error("Stripe Card Update Failure - #{current_user.username}")
      redirect_to "/settings/billing", flash: { error:
        "There was a problem updating your billing info." }
    end
  rescue Stripe::CardError => e
    flash[:error] = e.message
    redirect_to "/settings/billing"
  end

  def destroy
    authorize :stripe_active_card
    customer = Stripe::Customer.retrieve(current_user.stripe_id_code)
    if customer.subscriptions.count.zero? || customer.sources.all(object: "card").count > 1
      customer.sources.retrieve(params[:id]).delete
      customer.save
      redirect_to "/settings/billing",
                  notice: "Your card has been successfully removed."
    else
      redirect_to "/settings/billing", flash: { error:
        "Can't remove card if you have an active membership. Please cancel your membership first." }
    end
  end

  def find_or_create_customer
    if current_user.stripe_id_code.present?
      Stripe::Customer.retrieve(current_user.stripe_id_code)
    else
      customer = Stripe::Customer.create(
        email: current_user.email,
        source: params[:stripe_token],
      )
      current_user.update(stripe_id_code: customer.id)
      customer
    end
  end

  def stripe_params
    accessible = %i[id stripe_token]
    params.permit(accessible)
  end
end
