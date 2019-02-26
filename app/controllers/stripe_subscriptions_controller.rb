class StripeSubscriptionsController < ApplicationController
  before_action :authenticate_user!
  before_action :touch_current_user

  def create
    authorize :stripe_subscription
    amount = stripe_params[:amount]
    customer = find_or_create_customer
    if customer &&
        MembershipService.new(customer, current_user, amount).subscribe_customer
      logger.info("Stripe New Subscription Success - #{current_user.username}")
    else
      logger.error("Stripe New Subscription Failure - #{current_user.username}")
      redirect_to "/membership", flash: { error:
                                          "There was a problem updating your billing info." }
    end
  rescue Stripe::CardError, Stripe::InvalidRequestError => e
    logger.error("Stripe Error - #{e.message} - #{current_user.email}")
    message = if e.message.include?("This customer has no attached payment source")
                "Something went wrong! Please try again or contact members@dev.to."
              else
                e.message
              end
    redirect_to "/membership", flash: { error: message }
  end

  def update
    authorize :stripe_subscription
    amount = stripe_params[:amount]
    customer = Stripe::Customer.retrieve(current_user.stripe_id_code)
    if MembershipService.new(customer, current_user, amount).update_subscription
      logger.info("Stripe Update Subscription Success - #{current_user.username}")
      redirect_to "/settings/membership", notice:
        "Your new membership is now active. Thanks for your support!"
    else
      logger.error("Stripe Update Subscription Failure - #{current_user.username}")
      redirect_to "/settings/membership", flash: { error:
        "There was a problem updating your new plan." }
    end
  rescue Stripe::CardError, Stripe::InvalidRequestError => e
    redirect_to "/settings/billing", flash: { error: e.message }
  end

  def destroy
    authorize :stripe_subscription
    customer = Stripe::Customer.retrieve(current_user.stripe_id_code)
    if MembershipService.new(customer, current_user, nil).unsubscribe_customer
      logger.info("Stripe Cancel Subscription Success - #{current_user.username}")
      redirect_to "/settings", notice:
        "Your membership is cancelled. Thanks for your support."
    else
      logger.info("Stripe Cancel Subscription Failure - #{current_user.username}")
      redirect_to "/settings", flash: { error:
        "There was a problem updating your plan." }
    end
  end

  private

  def find_or_create_customer
    if current_user.stripe_id_code.present?
      customer = Stripe::Customer.retrieve(current_user.stripe_id_code)
      customer.sources.create(source: params[:stripe_token]) if params[:stripe_token].present?
    else
      customer = Stripe::Customer.create(
        email: current_user.email,
        source: params[:stripe_token],
      )
    end
    customer
  end

  def stripe_params
    params[:amount] = convert_amount_to_cent
    raise custom_error if invalid_amount?

    accessible = %i[amount existing_card_id stripe_token]
    params.permit(accessible)
  end

  def custom_error
    message = <<-HTML
    Oops, something went wrong. You have not been charged.
    <br>
    Please
    #{view_context.link_to('try again', '/membership')} or #{view_context.link_to('contact us', 'mailto:members@dev.to')}.
    HTML
    Stripe::CardError.new(
      message.html_safe,
      params[:amount],
      400,
    )
  end

  def convert_amount_to_cent
    amount = params[:amount] || params[:input_amount]
    amount ? (amount.to_d * 100).to_i : nil
  end

  def invalid_amount?
    amount = params[:amount] || params[:input_amount]
    amount.nil? || amount < 100
  end
end
