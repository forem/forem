module StripeMock
  class Instance

    include StripeMock::RequestHandlers::Helpers
    include StripeMock::RequestHandlers::ParamValidators

    DUMMY_API_KEY = (0...32).map { (65 + rand(26)).chr }.join.downcase

    # Handlers are ordered by priority
    @@handlers = []

    def self.add_handler(route, name)
      @@handlers << {
        :route => %r{^#{route}$},
        :name => name
      }
    end

    def self.handler_for_method_url(method_url)
      @@handlers.find {|h| method_url =~ h[:route] }
    end

    include StripeMock::RequestHandlers::PaymentIntents
    include StripeMock::RequestHandlers::PaymentMethods
    include StripeMock::RequestHandlers::SetupIntents
    include StripeMock::RequestHandlers::ExternalAccounts
    include StripeMock::RequestHandlers::AccountLinks
    include StripeMock::RequestHandlers::ExpressLoginLinks
    include StripeMock::RequestHandlers::Accounts
    include StripeMock::RequestHandlers::Balance
    include StripeMock::RequestHandlers::BalanceTransactions
    include StripeMock::RequestHandlers::Charges
    include StripeMock::RequestHandlers::Cards
    include StripeMock::RequestHandlers::Sources
    include StripeMock::RequestHandlers::Subscriptions # must be before Customers
    include StripeMock::RequestHandlers::SubscriptionItems
    include StripeMock::RequestHandlers::Customers
    include StripeMock::RequestHandlers::Coupons
    include StripeMock::RequestHandlers::Disputes
    include StripeMock::RequestHandlers::Events
    include StripeMock::RequestHandlers::Invoices
    include StripeMock::RequestHandlers::InvoiceItems
    include StripeMock::RequestHandlers::Orders
    include StripeMock::RequestHandlers::Plans
    include StripeMock::RequestHandlers::Prices
    include StripeMock::RequestHandlers::Products
    include StripeMock::RequestHandlers::Refunds
    include StripeMock::RequestHandlers::Recipients
    include StripeMock::RequestHandlers::Transfers
    include StripeMock::RequestHandlers::Tokens
    include StripeMock::RequestHandlers::CountrySpec
    include StripeMock::RequestHandlers::Payouts
    include StripeMock::RequestHandlers::EphemeralKey
    include StripeMock::RequestHandlers::TaxRates
    include StripeMock::RequestHandlers::Checkout
    include StripeMock::RequestHandlers::Checkout::Session

    attr_reader :accounts, :balance, :balance_transactions, :bank_tokens, :charges, :coupons, :customers,
                :disputes, :events, :invoices, :invoice_items, :orders, :payment_intents, :payment_methods,
                :setup_intents, :plans, :prices, :recipients, :refunds, :transfers, :payouts, :subscriptions, :country_spec,
                :subscriptions_items, :products, :tax_rates, :checkout_sessions

    attr_accessor :error_queue, :debug, :conversion_rate, :account_balance

    def initialize
      @accounts = {}
      @balance = Data.mock_balance
      @balance_transactions = Data.mock_balance_transactions(['txn_05RsQX2eZvKYlo2C0FRTGSSA','txn_15RsQX2eZvKYlo2C0ERTYUIA', 'txn_25RsQX2eZvKYlo2C0ZXCVBNM', 'txn_35RsQX2eZvKYlo2C0QAZXSWE', 'txn_45RsQX2eZvKYlo2C0EDCVFRT', 'txn_55RsQX2eZvKYlo2C0OIKLJUY', 'txn_65RsQX2eZvKYlo2C0ASDFGHJ', 'txn_75RsQX2eZvKYlo2C0EDCXSWQ', 'txn_85RsQX2eZvKYlo2C0UJMCDET', 'txn_95RsQX2eZvKYlo2C0EDFRYUI'])
      @bank_tokens = {}
      @card_tokens = {}
      @customers = { Stripe.api_key => {} }
      @charges = {}
      @payment_intents = {}
      @payment_methods = {}
      @setup_intents = {}
      @coupons = {}
      @disputes = Data.mock_disputes(['dp_05RsQX2eZvKYlo2C0FRTGSSA','dp_15RsQX2eZvKYlo2C0ERTYUIA', 'dp_25RsQX2eZvKYlo2C0ZXCVBNM', 'dp_35RsQX2eZvKYlo2C0QAZXSWE', 'dp_45RsQX2eZvKYlo2C0EDCVFRT', 'dp_55RsQX2eZvKYlo2C0OIKLJUY', 'dp_65RsQX2eZvKYlo2C0ASDFGHJ', 'dp_75RsQX2eZvKYlo2C0EDCXSWQ', 'dp_85RsQX2eZvKYlo2C0UJMCDET', 'dp_95RsQX2eZvKYlo2C0EDFRYUI'])
      @events = {}
      @invoices = {}
      @invoice_items = {}
      @orders = {}
      @payment_methods = {}
      @plans = {}
      @prices = {}
      @products = {}
      @recipients = {}
      @refunds = {}
      @transfers = {}
      @payouts = {}
      @subscriptions = {}
      @subscriptions_items = {}
      @country_spec = {}
      @tax_rates = {}
      @checkout_sessions = {}

      @debug = false
      @error_queue = ErrorQueue.new
      @id_counter = 0
      @balance_transaction_counter = 0
      @dispute_counter = 0
      @conversion_rate = 1.0
      @account_balance = 10000

      # This is basically a cache for ParamValidators
      @base_strategy = TestStrategies::Base.new
    end

    def mock_request(method, url, api_key: nil, api_base: nil, params: {}, headers: {})
      return {} if method == :xtest

      api_key ||= (Stripe.api_key || DUMMY_API_KEY)

      # Ensure params hash has symbols as keys
      params = Stripe::Util.symbolize_names(params)

      method_url = "#{method} #{url}"

      if handler = Instance.handler_for_method_url(method_url)
        if @debug == true
          puts "- - - - " * 8
          puts "[StripeMock req]::#{handler[:name]} #{method} #{url}"
          puts "                  #{params}"
        end

        if mock_error = @error_queue.error_for_handler_name(handler[:name])
          @error_queue.dequeue
          raise mock_error
        else
          res = self.send(handler[:name], handler[:route], method_url, params, headers)
          puts "           [res]  #{res}" if @debug == true
          [to_faraday_hash(res), api_key]
        end
      else
        puts "[StripeMock] Warning : Unrecognized endpoint + method : [#{method} #{url}]"
        puts "[StripeMock] params: #{params}" unless params.empty?
        [{}, api_key]
      end
    end

    def generate_webhook_event(event_data)
      event_data[:id] ||= new_id 'evt'
      @events[ event_data[:id] ] = symbolize_names(event_data)
    end

    def upsert_stripe_object(object, attributes)
      # Most Stripe entities can be created via the API.  However, some entities are created when other Stripe entities are
      # created - such as when BalanceTransactions are created when Charges are created.  This method provides the ability
      # to create these internal entities.
      # It also provides the ability to modify existing Stripe entities.
      id = attributes[:id]
      if id.nil? || id == ""
        # Insert new Stripe object
        case object
          when :balance_transaction
            id = new_balance_transaction('txn', attributes)
          when :dispute
            id = new_dispute('dp', attributes)
          else
            raise UnsupportedRequestError.new "Unsupported stripe object `#{object}`"
        end
      else
        # Update existing Stripe object
        case object
          when :balance_transaction
            btxn = assert_existence :balance_transaction, id, @balance_transactions[id]
            btxn.merge!(attributes)
          when :dispute
            dispute = assert_existence :dispute, id, @disputes[id]
            dispute.merge!(attributes)
          else
            raise UnsupportedRequestError.new "Unsupported stripe object `#{object}`"
        end
      end
      id
    end

    private

    def assert_existence(type, id, obj, message=nil)
      if obj.nil?
        msg = message || "No such #{type}: #{id}"
        raise Stripe::InvalidRequestError.new(msg, type.to_s, http_status: 404)
      end
      obj
    end

    def new_id(prefix)
      # Stripe ids must be strings
      "#{StripeMock.global_id_prefix}#{prefix}_#{@id_counter += 1}"
    end

    def new_balance_transaction(prefix, params = {})
      # balance transaction ids must be strings
      id = "#{StripeMock.global_id_prefix}#{prefix}_#{@balance_transaction_counter += 1}"
      amount = params[:amount]
      unless amount.nil?
        # Fee calculation
        calculate_fees(params) unless params[:fee]
        params[:net] = amount - params[:fee]
        params[:amount] = amount * @conversion_rate
      end
      @balance_transactions[id] = Data.mock_balance_transaction(params.merge(id: id))
      id
    end

    def new_dispute(prefix, params = {})
      id = "#{StripeMock.global_id_prefix}#{prefix}_#{@dispute_counter += 1}"
      @disputes[id] = Data.mock_dispute(params.merge(id: id))
      id
    end

    def symbolize_names(hash)
      Stripe::Util.symbolize_names(hash)
    end

    def to_faraday_hash(hash)
      response = Struct.new(:data)
      response.new(hash)
    end

    def calculate_fees(params)
      application_fee = params[:application_fee] || 0
      params[:fee] = processing_fee(params[:amount]) + application_fee
      params[:fee_details] = [
        {
          amount: processing_fee(params[:amount]),
          application: nil,
          currency: params[:currency] || StripeMock.default_currency,
          description: "Stripe processing fees",
          type: "stripe_fee"
        }
      ]
      if application_fee
        params[:fee_details] << {
          amount: application_fee,
          currency: params[:currency] || StripeMock.default_currency,
          description: "Application fee",
          type: "application_fee"
        }
      end
    end

    def processing_fee(amount)
      (30 + (amount.abs * 0.029).ceil) * (amount > 0 ? 1 : -1)
    end
  end
end
