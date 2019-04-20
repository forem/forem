class CreditsController < ApplicationController
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
    make_payment
    credit_objects = []
    params[:credit][:number_to_purchase].to_i.times do
      if params[:user_type] == "organization"
        raise unless current_user.org_admin
        credit_objects << Credit.new(organization_id: current_user.organization_id)
      else
        credit_objects << Credit.new(user_id: current_user.id)
      end
    end
    Credit.import credit_objects
    redirect_to "/credits"
  end

  def make_payment
    # Amount in cents
    @amount = 500
    customer = if current_user.stripe_id_code
                 Stripe::Customer.retrieve(current_user.stripe_id_code)
               else
                 Stripe::Customer.create({
                   email: current_user.email
                 })
               end
    if params[:stripe_token]
      card = Stripe::Customer.create_source(
        customer.id,
        {
          source: params[:stripe_token],
        }
      )
    else
      card = customer.sources.retrieve(params[:selected_card])
    end
    current_user.update_column(:stripe_id_code, customer.id) if current_user.stripe_id_code.nil?
    charge = Stripe::Charge.create({
      customer: customer.id,
      source: card || customer.default_source,
      amount: @amount,
      description: "Purchase of credits #{params[:credit][:number_to_purchase]}",
      currency: 'usd',
    })
  
  rescue Stripe::CardError => e
    flash[:error] = e.message
    redirect_to new_charge_path
  end
end