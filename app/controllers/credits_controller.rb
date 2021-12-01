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

    if validate_input(number_to_purchase)
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
    else
      redirect_to purchase_credits_path
    end
  end

  def validate_input(number_to_purchase)
    # these both set flash[:error] as a side-effect before returning false.
    ensure_payment_option! && ensure_nonzero_amount!(number_to_purchase)
  end

  def ensure_payment_option!
    # we need either a credit card, a stripe token, or an organization (with billing setup)
    # to complete the payment
    purchase_options = params.slice(:selected_card, :stripe_token, :organization_id).compact_blank
    return true if purchase_options.present?

    flash[:error] = "Please add a credit card before purchasing"
    false
  end

  def ensure_nonzero_amount!(number_to_purchase)
    return true if number_to_purchase.positive?

    flash[:error] = "At least one credit must be purchased"
    false
  end
end
