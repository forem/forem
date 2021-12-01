class CreditsController < ApplicationController
  before_action :authenticate_user!
  before_action :initialize_stripe

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
    @customer = Payments::Customer.get(current_user.stripe_id_code) if current_user.stripe_id_code
  end

  def create
    not_authorized if params[:organization_id].present? && !current_user.org_admin?(params[:organization_id])

    number_to_purchase = params[:credit][:number_to_purchase].to_i

    ensure_selected_card!
    ensure_nonzero_amount!(number_to_purchase)

    payment = Payments::ProcessCreditPurchase.call(
      current_user,
      number_to_purchase,
      purchase_options: params.slice(:stripe_token, :selected_card, :organization_id),
    )

    if payment.success?
      @purchaser = payment.purchaser
      redirect_to credits_path, notice: "#{number_to_purchase} new credits purchased!"
    else
      flash[:error] = payment.error
      redirect_to purchase_credits_path
    end
  end

  def ensure_selected_card!
    return if params[:selected_card].present?

    flash[:error] = "Please add a credit card before purchasing"
    redirect_to purchase_credits_path
  end

  def ensure_nonzero_amount!(number_to_purchase)
    return if number_to_purchase.positive?

    flash[:error] = "At least one credit must be purchased"
    redirect_to purchase_credits_path
  end
end
