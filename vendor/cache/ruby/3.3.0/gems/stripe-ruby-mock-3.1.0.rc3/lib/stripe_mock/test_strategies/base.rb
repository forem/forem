module StripeMock
  module TestStrategies
    class Base

      def list_products(limit)
        Stripe::Product.list(limit: limit)
      end

      def create_product(params = {})
        Stripe::Product.create create_product_params(params)
      end

      def create_product_params(params={})
        {
          :id => 'stripe_mock_default_product_id',
          :name => 'Default Product',
        }.merge(params)
      end

      def retrieve_product(product_id)
        Stripe::Product.retrieve(product_id)
      end


      def list_plans(limit)
        Stripe::Plan.list(limit: limit)
      end

      def create_plan(params={})
        Stripe::Plan.create create_plan_params(params)
      end

      def create_plan_params(params={})
        {
          :id => 'stripe_mock_default_plan_id',
          :interval => 'month',
          :currency => StripeMock.default_currency,
          :product => nil, # need to override yourself to pass validations
          :amount => 1337
        }.merge(params)
      end

      def create_price(params={})
        Stripe::Price.create create_price_params(params)
      end

      def create_price_params(params={})
        {
          :currency => StripeMock.default_currency,
        }.merge(params)
      end

      def list_subscriptions(limit)
        Stripe::Subscription.list(limit: limit)
      end


      def generate_card_token(card_params={})
        card_data = { :number => "4242424242424242", :exp_month => 9, :exp_year => (Time.now.year + 5), :cvc => "999", :tokenization_method => nil }
        card = StripeMock::Util.card_merge(card_data, card_params)
        card[:fingerprint] = StripeMock::Util.fingerprint(card[:number]) if StripeMock.state == 'local'

        stripe_token = Stripe::Token.create(:card => card)
        stripe_token.id
      end

      def generate_bank_token(bank_account_params={})
        currency = bank_account_params[:currency] || StripeMock.default_currency
        bank_account = {
          :country => "US",
          :currency => currency,
          :account_holder_name => "Jane Austen",
          :account_holder_type => "individual",
          :routing_number => "110000000",
          :account_number => "000123456789"
        }.merge(bank_account_params)
        bank_account[:fingerprint] = StripeMock::Util.fingerprint(bank_account[:account_number]) if StripeMock.state == 'local'

        stripe_token = Stripe::Token.create(:bank_account => bank_account)
        stripe_token.id
      end


      def create_coupon_params(params = {})
        currency = params[:currency] || StripeMock.default_currency
        {
          id: '10BUCKS',
          amount_off: 1000,
          currency: currency,
          max_redemptions: 100,
          metadata: {
            created_by: 'admin_acct_1'
          },
          duration: 'once'
        }.merge(params)
      end

      def create_coupon_percent_of_params(params = {})
        {
          id: '25PERCENT',
          percent_off: 25,
          redeem_by: nil,
          duration_in_months: 3,
          duration: :repeating
        }.merge(params)
      end

      def create_checkout_session_params(params = {})
        {
            payment_method_types: ['card'],
            line_items: [{
                             name: 'T-shirt',
                             quantity: 1,
                             amount: 500,
                             currency: 'usd',
                         }],
        }.merge(params)
      end


      def create_coupon(params = {})
        Stripe::Coupon.create create_coupon_params(params)
      end

      def create_checkout_session(params = {})
        Stripe::Checkout::Session.create create_checkout_session_params(params)
      end

      def delete_all_coupons
        coupons = Stripe::Coupon.list
        coupons.data.map(&:delete) if coupons.data.count > 0
      end

      def prepare_card_error
        StripeMock.prepare_card_error(:card_error, :new_customer) if StripeMock.state == 'local'
      end

    end
  end
end
