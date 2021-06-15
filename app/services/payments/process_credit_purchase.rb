module Payments
  # This service encapsulates purchasing credits via the Stripe API.
  #
  # NOTE: We still use the legacy checkout API here. While this doesn't
  # support all features of Stripe's new API (e.g. SCA) it's well suited
  # for our use-case of occasional one-off purchases.
  # An exploration of alternatives and the decision to stick to the legacy API
  # can be found here: https://github.com/forem/internalEngineering/issues/364
  class ProcessCreditPurchase
    def self.call(user, credits_count, purchase_options:)
      new(
        user,
        credits_count,
        purchase_options: purchase_options,
      ).call
    end

    attr_reader :purchaser, :error

    def initialize(user, credits_count, purchase_options:)
      self.user = user
      self.credits_count = credits_count
      self.purchase_options = purchase_options
      self.success = false
    end

    def call
      process_purchase
      create_credits if success?
      self
    end

    def success?
      success
    end

    private

    attr_accessor :user, :credits_count, :success, :purchase_options
    attr_writer :purchaser, :error

    def process_purchase
      customer = find_or_create_customer
      update_user_stripe_info(customer)
      card = find_or_create_card(customer)
      create_charge(customer, card)
      self.success = true
    rescue Payments::PaymentsError => e
      self.error = e.message
    end

    def find_or_create_customer
      if user.stripe_id_code
        Payments::Customer.get(user.stripe_id_code)
      else
        Payments::Customer.create(email: user.email)
      end
    end

    def find_or_create_card(customer)
      if purchase_options[:stripe_token]
        Payments::Customer.create_source(customer.id, purchase_options[:stripe_token])
      else
        Payments::Customer.get_source(customer, purchase_options[:selected_card])
      end
    end

    def update_user_stripe_info(customer)
      user.update_column(:stripe_id_code, customer.id) if user.stripe_id_code.nil?
    end

    def create_charge(customer, card)
      Payments::Customer.charge(
        customer: customer,
        amount: credits_count * cost_per_credit,
        description: "Purchase of #{credits_count} credits.",
        card_id: card&.id,
      )
    end

    def create_credits
      purchaser = user

      credits_attributes = Array.new(credits_count) do
        # unfortunately Rails requires the timestamps to be present and doesn't add them automatically
        # see <https://github.com/rails/rails/issues/35493>
        now = Time.current
        attrs = { created_at: now, updated_at: now, cost: cost_per_credit / 100.0 }

        if purchase_options[:organization_id].present?
          purchaser = Organization.find(purchase_options[:organization_id])
          attrs[:organization_id] = purchase_options[:organization_id]
        else
          attrs[:user_id] = user.id
        end

        attrs
      end

      Credit.insert_all(credits_attributes)
      purchaser.update(
        credits_count: purchaser.credits.size,
        spent_credits_count: purchaser.credits.spent.size,
        unspent_credits_count: purchaser.credits.unspent.size,
      )
      self.purchaser = purchaser
    end

    def cost_per_credit
      prices = Settings::General.credit_prices_in_cents

      case credits_count
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
end
