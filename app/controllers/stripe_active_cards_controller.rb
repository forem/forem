class StripeActiveCardsController < ApplicationController
  before_action :authenticate_user!
  before_action :initialize_stripe

  AUDIT_LOG_CATEGORY = "user.credit_card.edit".freeze
  private_constant :AUDIT_LOG_CATEGORY

  STRIPE_PERMITTED_PARAMS = %i[stripe_token].freeze

  def create
    authorize :stripe_active_card

    customer = find_or_create_customer

    if Payments::Customer.create_source(customer.id, stripe_params[:stripe_token])
      flash[:settings_notice] = "Your billing information has been updated"
      audit_log("add")
    else
      ForemStatsClient.increment("stripe.errors", tags: ["action:create_card", "user_id:#{current_user.id}"])

      flash[:error] = "There was a problem updating your billing info."
    end
    redirect_to user_settings_path(:billing)
  rescue Payments::CardError, Payments::InvalidRequestError => e
    ForemStatsClient.increment("stripe.errors", tags: ["action:create_card", "user_id:#{current_user.id}"])
    redirect_to user_settings_path(:billing), flash: { error: e.message }
  end

  def update
    authorize :stripe_active_card

    # change the default card
    customer = find_customer
    card = Payments::Customer.get_source(customer, params[:id])
    customer.default_source = card.id

    if Payments::Customer.save(customer)
      flash[:settings_notice] = "Your billing information has been updated"
      audit_log("update")
    else
      ForemStatsClient.increment("stripe.errors", tags: ["action:update_card", "user_id:#{current_user.id}"])
      flash[:error] = "There was a problem updating your billing info."
    end

    redirect_to user_settings_path(:billing)
  rescue Payments::CardError, Payments::InvalidRequestError => e
    ForemStatsClient.increment("stripe.errors", tags: ["action:update_card", "user_id:#{current_user.id}"])

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
      audit_log("remove")
    end

    redirect_to user_settings_path(:billing)
  rescue Payments::InvalidRequestError => e
    ForemStatsClient.increment("stripe.errors")

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
    params.permit(STRIPE_PERMITTED_PARAMS)
  end

  def audit_log(user_action)
    AuditLog.create(
      category: AUDIT_LOG_CATEGORY,
      user: current_user,
      roles: current_user.roles_name,
      slug: "credit_card_#{user_action}",
      data: {
        action: action_name,
        controller: controller_name,
        user_action: user_action
      },
    )
  end
end
