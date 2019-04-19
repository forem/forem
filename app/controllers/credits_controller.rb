class CreditsController < ApplicationController
  def index
    @credits = current_user.credits.where(spent: false)
  end

  def new
    @credit = Credit.new
  end

  def create
    make_payment
    credit_objects = []
    params[:credit][:number_to_purchase].to_i.times do
      credit_objects << Credit.new(user_id: current_user.id)
    end
    Credit.import credit_objects
    redirect_to "/credits"
  end

  def make_payment
    # Amount in cents
    @amount = 500
  
    customer = Stripe::Customer.create({
      email: current_user.email,
      source: params[:stripe_token],
    })
  
    charge = Stripe::Charge.create({
      customer: customer.id,
      amount: @amount,
      description: "Purchase of credits #{params[:credit][:number_to_purchase]}",
      currency: 'usd',
    })
  
  rescue Stripe::CardError => e
    flash[:error] = e.message
    redirect_to new_charge_path
  end
end