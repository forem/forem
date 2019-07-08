class CreditsController < ApplicationController
  before_action :authenticate_user!

  def index
    @user_unspent_credits_count = current_user.credits.unspent.size
    @ledger = Credits::Ledger.call(current_user)

    @organizations = current_user.admin_organizations
  end

  def new
    @credit = Credit.new
    @purchaser = if params[:organization_id].present? && current_user.org_admin?(params[:organization_id])
                   Organization.find_by(id: params[:organization_id])
                 else
                   current_user
                 end
    @organizations = current_user.admin_organizations
    @customer = Stripe::Customer.retrieve(current_user.stripe_id_code) if current_user.stripe_id_code
  end

  def create
    not_authorized if params[:organization_id].present? && !current_user.org_admin?(params[:organization_id])

    @number_to_purchase = params[:credit][:number_to_purchase].to_i

    return unless make_payment

    credit_objects = Array.new(@number_to_purchase) do
      if params[:organization_id].present?
        @purchaser = Organization.find(params[:organization_id])
        Credit.new(organization_id: params[:organization_id], cost: cost_per_credit / 100.0)
      else
        @purchaser = current_user
        Credit.new(user_id: current_user.id, cost: cost_per_credit / 100.0)
      end
    end
    Credit.import credit_objects
    @purchaser.credits_count = @purchaser.credits.size
    @purchaser.spent_credits_count = @purchaser.credits.spent.size
    @purchaser.unspent_credits_count = @purchaser.credits.unspent.size
    @purchaser.save
    redirect_to credits_path, notice: "#{@number_to_purchase} new credits purchased!"
  end

  def make_payment
    find_or_create_customer
    find_or_create_card
    update_user_stripe_info
    create_charge
    true
  rescue Stripe::CardError => e
    flash[:error] = e.message
    redirect_to purchase_credits_path
    false
  end

  def find_or_create_customer
    @customer = if current_user.stripe_id_code
                  Stripe::Customer.retrieve(current_user.stripe_id_code)
                else
                  Stripe::Customer.create(
                    email: current_user.email,
                  )
                end
  end

  def find_or_create_card
    @card = if params[:stripe_token]
              Stripe::Customer.create_source(
                @customer.id,
                source: params[:stripe_token],
              )
            else
              @customer.sources.retrieve(params[:selected_card])
            end
  end

  def update_user_stripe_info
    current_user.update_column(:stripe_id_code, @customer.id) if current_user.stripe_id_code.nil?
  end

  def create_charge
    @amount = generate_cost
    source = Rails.env.test? ? @card.id : (@card || @customer.default_source)
    Stripe::Charge.create(
      customer: @customer.id,
      source: source,
      amount: @amount,
      description: "Purchase of #{@number_to_purchase} credits.",
      currency: "usd",
    )
  end

  def generate_cost
    @number_to_purchase * cost_per_credit
  end

  def cost_per_credit
    if @number_to_purchase < 10
      500
    elsif @number_to_purchase < 100
      400
    elsif @number_to_purchase < 1000
      300
    else
      250
    end
  end
end
