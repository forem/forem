class StripeCancellationsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: :create

  def create
    event = Stripe::Event.retrieve(params[:id])
    stripe_id = event.data.object.customer
    customer = Stripe::Customer.retrieve(stripe_id)
    monthly_dues = event.data.object.plan.amount
    user = User.where(stripe_id_code: stripe_id).first
    MembershipService.new(customer, user, monthly_dues).unsubscribe_customer
    render body: nil, status: 201
  rescue Stripe::APIConnectionError, Stripe::StripeError
    render body: nil, status: 400
  end
end
