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

    @number_to_purchase = params[:credit][:number_to_purchase].to_i

    return unless make_payment

    credits_attributes = Array.new(@number_to_purchase) do
      # unfortunately Rails requires the timestamps to be present and doesn't add them automatically
      # see <https://github.com/rails/rails/issues/35493>
      now = Time.current
      attrs = { created_at: now, updated_at: now, cost: cost_per_credit / 100.0 }

      if params[:organization_id].present?
        @purchaser = Organization.find(params[:organization_id])
        attrs[:organization_id] = params[:organization_id]
      else
        @purchaser = current_user
        attrs[:user_id] = current_user.id
      end

      attrs
    end
    Credit.insert_all(credits_attributes)

    @purchaser.credits_count = @purchaser.credits.size
    @purchaser.spent_credits_count = @purchaser.credits.spent.size
    @purchaser.unspent_credits_count = @purchaser.credits.unspent.size
    @purchaser.save
    redirect_to credits_path, notice: "#{@number_to_purchase} new credits purchased!"
  end

  private

  def make_payment
    find_or_create_customer
    find_or_create_card
    update_user_stripe_info
    create_charge
    true
  rescue Payments::PaymentsError => e
    flash[:error] = e.message
    redirect_to purchase_credits_path
    false
  end

  def find_or_create_customer
    @customer = if current_user.stripe_id_code
                  Payments::Customer.get(current_user.stripe_id_code)
                else
                  Payments::Customer.create(email: current_user.email)
                end
  end

  def find_or_create_card
    @card = if params[:stripe_token]
              Payments::Customer.create_source(@customer.id, params[:stripe_token])
            else
              Payments::Customer.get_source(@customer, params[:selected_card])
            end
  end

  def update_user_stripe_info
    current_user.update_column(:stripe_id_code, @customer.id) if current_user.stripe_id_code.nil?
  end

  def create_charge
    Payments::Customer.charge(
      customer: @customer,
      amount: generate_cost,
      description: "Purchase of #{@number_to_purchase} credits.",
      card_id: @card&.id,
    )
  end

  def generate_cost
    @number_to_purchase * cost_per_credit
  end

  def cost_per_credit
    prices = Settings::General.credit_prices_in_cents

    case @number_to_purchase
    when ..9
      prices[:small]
    when 10..99
      prices[:medium]
    when 100..999
      prices[:large]
    else
      prices[:xlarge]
    end
  end
end
