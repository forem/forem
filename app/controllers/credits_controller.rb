class CreditsController < ApplicationController
  before_action :authenticate_user!

  def index
    @credits = current_user.credits.where(spent: false)
    @org_credits = current_user.organization.credits.where(spent: false) if current_user.org_admin
  end

  def new
    @credit = Credit.new
    @purchaser = params[:purchaser] == "organization" ? current_user.organization : current_user
    @customer = Stripe::Customer.retrieve(current_user.stripe_id_code) if current_user.stripe_id_code
  end

  def create
    @number_to_purchase = params[:credit][:number_to_purchase].to_i
    make_payment
    credit_objects = []
    @number_to_purchase.times do
      if params[:user_type] == "organization"
        raise unless current_user.org_admin

        credit_objects << Credit.new(organization_id: current_user.organization_id, cost: cost_per_credit / 100.0)
      else
        credit_objects << Credit.new(user_id: current_user.id, cost: cost_per_credit / 100.0)
      end
    end
    Credit.import credit_objects
    redirect_to "/credits", notice: "#{@number_to_purchase} new credits purchased!"
  end

  def make_payment
    find_or_create_customer
    find_or_create_card
    update_user_stripe_info
    create_charge
  rescue Stripe::CardError => e
    flash[:error] = e.message
    redirect_to "/credits/new"
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
    Stripe::Charge.create(
      customer: @customer.id,
      source: @card || @customer.default_source,
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
    elsif @number_to_purchase < 10
      400
    elsif @number_to_purchase < 100
      300
    else
      250
    end
  end
end
