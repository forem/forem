module StripeMock
  module Data

    def self.mock_account(params = {})
      id = params[:id] || 'acct_103ED82ePvKYlo2C'
      currency = params[:currency] || StripeMock.default_currency
      {
        id: id,
        email: "bob@example.com",
        statement_descriptor: nil,
        display_name: "Stripe.com",
        timezone: "US/Pacific",
        details_submitted: false,
        charges_enabled: false,
        payouts_enabled: false,
        currencies_supported: [
          "usd"
        ],
        default_currency: currency,
        country: "US",
        object: "account",
        business_name: "Stripe.com",
        business_url: nil,
        support_phone: nil,
        managed: false,
        product_description: nil,
        debit_negative_balances: true,
        bank_accounts: {
          object: "list",
          total_count: 0,
          has_more: false,
          url: "/v1/accounts/#{id}/bank_accounts",
          data: [

          ]
        },
        verification: {
          fields_needed: [],
          due_by: nil,
          contacted: false
        },
        transfer_schedule: {
          delay_days: 7,
          interval: "daily"
        },
        tos_acceptance: {
          ip: nil,
          date: nil,
          user_agent: nil
        },
        external_accounts: {
            object: "list",
            data: [

            ],
            has_more: false,
            total_count: 0,
            url: "/v1/accounts/#{id}/external_accounts"
        },
        legal_entity: {
          type: nil,
          business_name: nil,
          address: {
            line1: nil,
            line2: nil,
            city: nil,
            state: nil,
            postal_code: nil,
            country: "US"
          },
          first_name: nil,
          last_name: nil,
          personal_address: {
            line1: nil,
            line2: nil,
            city: nil,
            state: nil,
            postal_code: nil,
            country: nil
          },
          dob: {
            day: nil,
            month: nil,
            year: nil
          },
          additional_owners: nil,
          verification: {
            status: "unverified",
            document: nil,
            details: nil
          }
        },
        decline_charge_on: {
          cvc_failure: false,
          avs_failure: false
        },
        keys: {
          secret: "sk_test_AmJhMTLPtY9JL4c6EG0",
          publishable: "pk_test_2rSaMTLPtY9JL449dsf"
        }
      }.merge(params)
    end

    def self.mock_account_link(params = {})
      now = Time.now.to_i
      {
        object: 'account_link',
        created: now,
        expires_at: now + 300,
        url: 'https://connect.stripe.com/setup/c/iB0ph1cPnRLY',
        data: {}
      }.merge(params)
    end

    def self.mock_express_login_link(params = {})
      now = Time.now.to_i
      {
        object: 'login_link',
        created: now,
        url: 'https://connect.stripe.com/express/Ln7FfnNpUcCU',
        data: {}
      }.merge(params)
    end

    def self.mock_tax_rate(params)
      {
        id: 'test_cus_default',
        object: 'tax_rate',
        active: true,
        created: 1559079603,
        description: nil,
        display_name: 'VAT',
        inclusive: false,
        jurisdiction: 'EU',
        livemode: false,
        metadata: {},
        percentage: 21.0
      }.merge(params)
    end

    def self.mock_customer(sources, params)
      cus_id = params[:id] || "test_cus_default"
      currency = params[:currency]
      sources.each {|source| source[:customer] = cus_id}
      {
        email: 'stripe_mock@example.com',
        description: 'an auto-generated stripe customer data mock',
        object: "customer",
        created: 1372126710,
        id: cus_id,
        name: nil,
        preferred_locales: [],
        livemode: false,
        delinquent: false,
        discount: nil,
        account_balance: 0,
        currency: currency,
        invoice_settings: {
          default_payment_method: nil,
          custom_fields: nil,
          footer: nil
        },
        sources: {
          object: "list",
          total_count: sources.size,
          has_more: false,
          url: "/v1/customers/#{cus_id}/sources",
          data: sources
        },
        subscriptions: {
          object: "list",
          total_count: 0,
          has_more: false,
          url: "/v1/customers/#{cus_id}/subscriptions",
          data: []
        },
        default_source: nil
      }.merge(params)
    end

    def self.mock_charge(params={})
      charge_id = params[:id] || "ch_1fD6uiR9FAA2zc"
      currency = params[:currency] || StripeMock.default_currency
      {
        id: charge_id,
        object: "charge",
        created: 1366194027,
        livemode: false,
        paid: true,
        amount: 0,
        application_fee: nil,
        application_fee_amount: nil,
        currency: currency,
        destination: nil,
        fraud_details: {},
        receipt_email: nil,
        receipt_number: nil,
        refunded: false,
        shipping: {},
        statement_descriptor: "Charge #{charge_id}",
        status: 'succeeded',
        source: {
          object: "card",
          last4: "4242",
          type: "Visa",
          brand: "Visa",
          funding: "credit",
          exp_month: 12,
          exp_year: 2013,
          fingerprint: "3TQGpK9JoY1GgXPw",
          country: "US",
          name: "name",
          address_line1: nil,
          address_line2: nil,
          address_city: nil,
          address_state: nil,
          address_zip: nil,
          address_country: nil,
          cvc_check: nil,
          address_line1_check: nil,
          address_zip_check: nil
        },
        captured: params.has_key?(:capture) ? params.delete(:capture) : true,
        refunds: {
          object: "list",
          total_count: 0,
          has_more: false,
          url: "/v1/charges/#{charge_id}/refunds",
          data: []
        },
        transfer: nil,
        balance_transaction: params[:balance_transaction] || "txn_2dyYXXP90MN26R",
        failure_message: nil,
        failure_code: nil,
        amount_refunded: 0,
        customer: nil,
        invoice: nil,
        description: nil,
        dispute: nil,
        metadata: {
        }
      }.merge(params)
    end

    def self.mock_refund(params={})
      currency = params[:currency] || StripeMock.default_currency
      {
        id: "re_4fWhgUh5si7InF",
        amount: 1,
        currency: currency,
        created: 1409165988,
        object: "refund",
        balance_transaction: "txn_4fWh2RKvgxcXqV",
        metadata: {},
        charge: "ch_4fWhYjzQ23UFWT",
        receipt_number: nil,
        status: "succeeded",
        reason: "requested_by_customer"
      }.merge(params)
    end

    def self.mock_charge_array
      {
        :data => [test_charge, test_charge, test_charge],
        :object => 'list',
        :url => '/v1/charges'
      }
    end

    def self.mock_card(params={})
      StripeMock::Util.card_merge({
        id: "test_cc_default",
        object: "card",
        last4: "4242",
        type: "Visa",
        brand: "Visa",
        funding: "credit",
        exp_month: 4,
        exp_year: 2016,
        fingerprint: "wXWJT135mEK107G8",
        customer: "test_cus_default",
        country: "US",
        name: "Johnny App",
        address_line1: nil,
        address_line2: nil,
        address_city: nil,
        address_state: nil,
        address_zip: nil,
        address_country: nil,
        cvc_check: nil,
        address_line1_check: nil,
        address_zip_check: nil,
        tokenization_method: nil,
        metadata: {}
      }, params)
    end

    def self.mock_bank_account(params={})
      currency = params[:currency] || StripeMock.default_currency
      {
        id: "test_ba_default",
        object: "bank_account",
        bank_name: "STRIPEMOCK TEST BANK",
        last4: "6789",
        routing_number: '110000000',
        country: "US",
        currency: currency,
        validated: false,
        status: 'new',
        account_holder_name: 'John Doe',
        account_holder_type: 'individual',
        fingerprint: "aBcFinGerPrINt123",
        metadata: {}
      }.merge(params)
    end

    def self.mock_coupon(params={})
      {
        :duration_in_months => 3,
        :percent_off => 25,
        :amount_off => nil,
        :currency => nil,
        :id => "co_test_coupon",
        :object => "coupon",
        :max_redemptions => nil,
        :redeem_by => nil,
        :times_redeemed => 0,
        :valid => true,
        :metadata => {},
      }.merge(params)
    end

    #FIXME nested overrides would be better than hardcoding plan_id
    def self.mock_subscription(params={})
      StripeMock::Util.rmerge({
        created: 1478204116,
        billing: 'charge_automatically',
        current_period_start: 1308595038,
        current_period_end: 1308681468,
        status: 'trialing',
        trial_from_plan: false,
        plan: {
          interval: 'month',
          amount: 7500,
          trial_period_days: 30,
          object: 'plan',
          id: '__test_plan_id__'
        },
        items: {
          object: 'list',
          data: [{
            id: 'si_1AwFf62eZvKYlo2C9u6Dhf9',
            created: 1504035973,
            metadata: {},
            object: 'subscription_item',
            plan: {
              amount: 999,
              created: 1504035972,
              currency: StripeMock.default_currency
            },
            quantity: 1
          }]
        },
        cancel_at_period_end: false,
        canceled_at: nil,
        collection_method: 'charge_automatically',
        ended_at: nil,
        start: 1308595038,
        object: 'subscription',
        trial_start: 1308595038,
        trial_end: 1308681468,
        customer: 'c_test_customer',
        quantity: 1,
        tax_percent: nil,
        discount: nil,
        metadata: {},
        default_tax_rates: nil,
        default_payment_method: nil,
        pending_invoice_item_interval: nil,
        next_pending_invoice_item_invoice: nil,
        latest_invoice: nil
      }, params)
    end

    def self.mock_invoice(lines, params={})
      in_id = params[:id] || "test_in_default"
      currency = params[:currency] || StripeMock.default_currency
      lines << Data.mock_line_item() if lines.empty?
      invoice = {
        id: 'in_test_invoice',
        status: 'open',
        invoice_pdf: 'pdf_url',
        hosted_invoice_url: 'hosted_invoice_url',
        created: 1349738950,
        period_end: 1349738950,
        period_start: 1349738950,
        due_date: nil,
        lines: {
          object: "list",
          total_count: lines.count,
          has_more: false,
          url: "/v1/invoices/#{in_id}/lines",
          data: lines
        },
        subtotal: lines.map {|line| line[:amount]}.reduce(0, :+),
        customer: "test_customer",
        object: 'invoice',
        attempted: false,
        application_fee: nil,
        closed: false,
        description: nil,
        forgiven: false,
        metadata: {},
        paid: false,
        receipt_number: nil,
        statement_descriptor: nil,
        tax: 10,
        tax_percent: nil,
        webhooks_delivered_at: 1349825350,
        livemode: false,
        attempt_count: 0,
        amount_due: 100,
        amount_paid: 0,
        currency: currency,
        starting_balance: 0,
        ending_balance: 0,
        next_payment_attempt: 1349825350,
        charge: nil,
        discount: nil,
        subscription: nil
      }.merge(params)
      if invoice[:discount]
        invoice[:total] = [0, invoice[:subtotal] - invoice[:discount][:coupon][:amount_off]].max if invoice[:discount][:coupon][:amount_off]
        invoice[:total] = invoice[:subtotal] * invoice[:discount][:coupon][:percent_off] / 100 if invoice[:discount][:coupon][:percent_off]
      else
        invoice[:total] = invoice[:subtotal]
      end
      due = invoice[:total] + invoice[:starting_balance]
      invoice[:amount_due] = due < 0 ? 0 : due
      invoice[:ending_balance] = invoice[:starting_balance] + invoice[:total] if invoice[:amount_due] == 0
      invoice
    end

    def self.mock_line_item(params = {})
      currency = params[:currency] || StripeMock.default_currency
      {
        id: "ii_test",
        object: "line_item",
        type: "invoiceitem",
        livemode: false,
        amount: 1000,
        currency: currency,
        discountable: false,
        proration: false,
        period: {
          start: 1349738920,
          end: 1349738920
        },
        tax_amounts: [
          {
            amount: 10
          }
        ],
        quantity: nil,
        subscription: nil,
        plan: nil,
        description: "Test invoice item",
        metadata: {}
      }.merge(params)
    end

    def self.mock_invoice_item(params = {})
      currency = params[:currency] || StripeMock.default_currency
      {
        id: "test_ii",
        object: "invoiceitem",
        created: 1349738920,
        amount: 1099,
        livemode: false,
        proration: false,
        currency: currency,
        customer: "cus_test",
        description: "invoice item desc",
        metadata: {},
        invoice: nil,
        subscription: nil
      }.merge(params)
    end

    def self.mock_paid_invoice
      test_invoice.merge({
          :attempt_count => 1,
          :attempted => true,
          :closed => true,
          :paid => true,
          :charge => 'ch_test_charge',
          :ending_balance => 0,
          :next_payment_attempt => nil,
        })
    end

    def self.mock_invoice_customer_array
      {
        :data => [test_invoice],
        :object => 'list',
        :url => '/v1/invoices?customer=test_customer'
      }
    end

    def self.mock_order(order_items, params)
      or_id = params[:id] || "test_or_default"
      currency = params[:currency] || 'eur'
      order_items << Data.mock_order_item if order_items.empty?
      {
        id: or_id,
        object: "order",
        amount: 5000,
        application: nil,
        application_fee: nil,
        charge: nil,
        created: 1448272783,
        currency: currency,
        customer: nil,
        email: nil,
        items: order_items,
        livemode: false,
        metadata: {},
        selected_shipping_method: nil,
        shipping: {
          address: {
            city: "Anytown",
            country: "US",
            line1: "1234 Main street",
            line2: nil,
            postal_code: "123456",
            state: nil
          },
          name: "Jenny Rosen",
          phone: nil
        },
        shipping_methods: nil,
        status: "created",
        updated: 1448272783
      }.merge(params)
    end

    def self.mock_order_item(params={})
      currency = params[:currency] || 'eur'
      {
        object: "order_item",
        amount: 5000,
        currency: currency,
        description: "Anyitem",
        parent: "sku_parent",
        quantity: 1,
        type: "sku"
      }.merge(params)
    end

    def self.mock_plan(params={})
      currency = params[:currency] || StripeMock.default_currency
      {
        id: "mock_plan_123",
        object: "plan",
        active: true,
        aggregate_usage: nil,
        amount: 2300,
        billing_scheme: "per_unit",
        created: 1466698898,
        currency: currency,
        interval: "month",
        interval_count: 1,
        livemode: false,
        metadata: {},
        nickname: "My Mock Plan",
        product: "mock_prod_NONEXIST", # override this with your own existing product id
        tiers: nil,
        tiers_mode: nil,
        transform_usage: nil,
        trial_period_days: nil,
        usage_type: "licensed"
      }.merge(params)
    end

    def self.mock_price(params={})
      currency = params[:currency] || StripeMock.default_currency
      {
        id: "mock_price_123",
        object: "price",
        active: true,
        billing_scheme: "per_unit",
        created: 1593044959,
        currency: currency,
        livemode: false,
        lookup_key: nil,
        metadata: {},
        nickname: 'My Mock Price',
        product: "mock_prod_NONEXIST",  # override this with your own existing product id
        recurring: {
          aggregate_usage: nil,
          interval: "month",
          interval_count: 1,
          usage_type: "licensed"
        },
        tiers_mode: nil,
        transform_quantity: nil,
        type: "recurring",
        unit_amount: 2000,
        unit_amount_decimal: "2000"
      }.merge(params)
    end

    def self.mock_product(params={})
      {
        id: "mock_prod_abc123",
        object: "product",
        active: true,
        attributes:[],
        caption: nil,
        created: 1466698000,
        deactivate_on: [],
        description: nil,
        images: [],
        livemode: false,
        metadata: {},
        name: "The Mock Product",
        package_dimensions: nil,
        shippable: nil,
        statement_descriptor: nil,
        type: "service",
        unit_label: "my_unit",
        updated: 1537939442,
        url: nil
      }.merge(params)
    end

    def self.mock_recipient(cards, params={})
      rp_id = params[:id] || "test_rp_default"
      cards.each {|card| card[:recipient] = rp_id}
      {
        name: "Stripe User",
        type: "individual",
        livemode: false,
        object: "recipient",
        id: rp_id,
        active_account: {
          last4: "6789",
          bank_name: "STRIPE TEST BANK",
          country: "US",
          object: "bank_account"
        },
        created: 1304114758,
        verified: true,
        metadata: {
        },
        cards: {
          object: "list",
          url: "/v1/recipients/#{rp_id}/cards",
          data: cards,
          has_more: false,
          total_count: cards.count
        },
        default_card: nil
      }.merge(params)
    end

    def self.mock_recipient_array
      {
        :data => [test_recipient, test_recipient, test_recipient],
        :object => 'list',
        :url => '/v1/recipients'
      }
    end

    def self.mock_card_token(params={})
      {
        :id => 'tok_default',
        :livemode => false,
        :used => false,
        :object => 'token',
        :type => 'card',
        :card => {
          :id => 'card_default',
          :object => 'card',
          :last4 => '2222',
          :type => 'Visa',
          :brand => 'Visa',
          :funding => 'credit',
          :exp_month => 9,
          :exp_year => 2017,
          :fingerprint => 'JRRLXGh38NiYygM7',
          :customer => nil,
          :country => 'US',
          :name => nil,
          :address_line1 => nil,
          :address_line2 => nil,
          :address_city => nil,
          :address_state => nil,
          :address_zip => nil,
          :address_country => nil
        }
      }.merge(params)
    end

    def self.mock_bank_account_token(params={})
      {
        :id => 'tok_default',
        :livemode => false,
        :used => false,
        :object => 'token',
        :type => 'bank_account',
        :bank_account => {
          :id => 'bank_account_default',
          :object => 'bank_account',
          :last4 => '2222',
          :fingerprint => 'JRRLXGh38NiYygM7',
        }
      }.merge(params)
    end

    def self.mock_transfer(params={})
      currency = params[:currency] || StripeMock.default_currency
      id = params[:id] || 'tr_test_transfer'
      {
        :amount => 100,
        :amount_reversed => 0,
        :balance_transaction => "txn_2dyYXXP90MN26R",
        :id => id,
        :livemode => false,
        :metadata => {},
        :currency => currency,
        :object => "transfer",
        :created => 1304114826,
        :description => "Transfer description",
        :reversed => false,
        :reversals => {
          :object => "list",
          :data => [],
          :total_count => 0,
          :has_more => false,
          :url => "/v1/transfers/#{id}/reversals"
        },
        :destination => "acct_164wxjKbnvuxQXGu",
        :destination_payment => "py_164xRvKbnvuxQXGuVFV2pZo1",
        :source_transaction => "ch_164xRv2eZvKYlo2Clu1sIJWB",
        :source_type => "card",
        :transfer_group => "group_ch_164xRv2eZvKYlo2Clu1sIJWB",
      }.merge(params)
    end

    def self.mock_payout(params={})
      currency = params[:currency] || StripeMock.default_currency
      id = params[:id] || 'po_test_payout'
      {
        :amount => 100,
        :id => id,
        :livemode => false,
        :metadata => {},
        :currency => currency,
        :object => "payout",
        :date => 1304114826,
        :description => "Payout description",
      }.merge(params)
    end

    def self.mock_disputes(ids=[])
      disputes = {}
      ids.each do |id|
        disputes[id] = self.mock_dispute(id: id)
      end
      disputes
    end

    def self.mock_dispute(params={})
      @timestamp ||= Time.now.to_i
      currency = params[:currency] || StripeMock.default_currency
      id = params[:id] || "dp_test_dispute"
      {
        :id => id,
        :object => "dispute",
        :amount => 195,
        :balance_transactions => [],
        :charge => "ch_15RsQR2eZvKYlo2CA8IfzCX0",
        :created => @timestamp += 1,
        :currency => currency,
        :evidence => self.mock_dispute_evidence,
        :evidence_details => self.mock_dispute_evidence_details,
        :is_charge_refundable => false,
        :livemode => false,
        :metadata => {},
        :reason => "general",
        :status => "under_review"
      }.merge(params)
    end

    def self.mock_dispute_evidence
      {
        :access_activity_log => nil,
        :billing_address => nil,
        :cancellation_policy => nil,
        :cancellation_policy_disclosure => nil,
        :cancellation_rebuttal => nil,
        :customer_communication => nil,
        :customer_email_address => nil,
        :customer_name => nil,
        :customer_purchase_ip => nil,
        :customer_signature => nil,
        :duplicate_charge_documentation => nil,
        :duplicate_charge_explanation => nil,
        :duplicate_charge_id => nil,
        :product_description => nil,
        :receipt => nil,
        :refund_policy => nil,
        :refund_policy_disclosure => nil,
        :refund_refusal_explanation => nil,
        :service_date => nil,
        :service_documentation => nil,
        :shipping_address => nil,
        :shipping_carrier => nil,
        :shipping_date => nil,
        :shipping_documentation => nil,
        :shipping_tracking_number => nil,
        :uncategorized_file => nil,
        :uncategorized_text => nil
      }
    end

    def self.mock_dispute_evidence_details
      {
        :due_by => 1424303999,
        :has_evidence => false,
        :past_due => false,
        :submission_count => 0
      }
    end

    def self.mock_transfer_array
      {
        :data => [test_transfer, test_transfer, test_transfer],
        :object => 'list',
        :url => '/v1/transfers'
      }
    end

    def self.mock_invalid_api_key_error
      {
        "error" => {
          "type" => "invalid_request_error",
          "message" => "Invalid API Key provided: invalid"
        }
      }
    end

    def self.mock_invalid_exp_year_error
      {
        "error" => {
          "code" => "invalid_expiry_year",
          "param" => "exp_year",
          "type" => "card_error",
          "message" => "Your card's expiration year is invalid"
        }
      }
    end

    def self.mock_missing_id_error
      {
        :error => {
          :param => "id",
          :type => "invalid_request_error",
          :message => "Missing id"
        }
      }
    end

    def self.mock_delete_subscription(params={})
      {
        deleted: true
      }.merge(params)
    end

    def self.mock_api_error
      {
        :error => {
          :type => "api_error"
        }
      }
    end

    def self.mock_delete_discount_response
      {
        :deleted => true,
        :id => "di_test_coupon"
      }
    end

    def self.mock_list_object(data, params={})
      list = StripeMock::Data::List.new(data, params)
      list.to_h
    end

    def self.mock_country_spec(country_code)
      id = country_code || "US"
      {
        "id"=> "US",
        "object"=> "country_spec",
        "default_currency"=> "usd",
        "supported_bank_account_currencies"=> {"usd"=>["US"]},
        "supported_payment_currencies"=> [
          "usd",
          "aed",
          "afn",
          "all",
          "amd",
          "ang",
          "aoa",
          "ars",
          "aud",
          "awg",
          "azn",
          "bam",
          "bbd",
          "bdt",
          "bgn",
          "bif",
          "bmd",
          "bnd",
          "bob",
          "brl",
          "bsd",
          "bwp",
          "bzd",
          "cad",
          "cdf",
          "chf",
          "clp",
          "cny",
          "cop",
          "crc",
          "cve",
          "czk",
          "djf",
          "dkk",
          "dop",
          "dzd",
          "egp",
          "etb",
          "eur",
          "fjd",
          "fkp",
          "gbp",
          "gel",
          "gip",
          "gmd",
          "gnf",
          "gtq",
          "gyd",
          "hkd",
          "hnl",
          "hrk",
          "htg",
          "huf",
          "idr",
          "ils",
          "inr",
          "isk",
          "jmd",
          "jpy",
          "kes",
          "kgs",
          "khr",
          "kmf",
          "krw",
          "kyd",
          "kzt",
          "lak",
          "lbp",
          "lkr",
          "lrd",
          "lsl",
          "ltl",
          "mad",
          "mdl",
          "mga",
          "mkd",
          "mnt",
          "mop",
          "mro",
          "mur",
          "mvr",
          "mwk",
          "mxn",
          "myr",
          "mzn",
          "nad",
          "ngn",
          "nio",
          "nok",
          "npr",
          "nzd",
          "pab",
          "pen",
          "pgk",
          "php",
          "pkr",
          "pln",
          "pyg",
          "qar",
          "ron",
          "rsd",
          "rub",
          "rwf",
          "sar",
          "sbd",
          "scr",
          "sek",
          "sgd",
          "shp",
          "sll",
          "sos",
          "srd",
          "std",
          "svc",
          "szl",
          "thb",
          "tjs",
          "top",
          "try",
          "ttd",
          "twd",
          "tzs",
          "uah",
          "ugx",
          "uyu",
          "uzs",
          "vnd",
          "vuv",
          "wst",
          "xaf",
          "xcd",
          "xof",
          "xpf",
          "yer",
          "zar",
          "zmw"
        ],
        "supported_payment_methods"=> [
          "alipay",
          "card",
          "stripe"
        ],
        "verification_fields"=> {"individual"=>{"minimum"=>["external_account","legal_entity.address.city","legal_entity.address.line1","legal_entity.address.postal_code","legal_entity.address.state","legal_entity.dob.day","legal_entity.dob.month","legal_entity.dob.year","legal_entity.first_name","legal_entity.last_name","legal_entity.personal_id_number","legal_entity.ssn_last_4","legal_entity.type","tos_acceptance.date","tos_acceptance.ip"],"additional"=>["legal_entity.personal_id_number","legal_entity.verification.document"]},"company"=>{"minimum"=>["external_account","legal_entity.address.city","legal_entity.address.line1","legal_entity.address.postal_code","legal_entity.address.state","legal_entity.business_name","legal_entity.business_tax_id","legal_entity.dob.day","legal_entity.dob.month","legal_entity.dob.year","legal_entity.first_name","legal_entity.last_name","legal_entity.ssn_last_4","legal_entity.type","tos_acceptance.date","tos_acceptance.ip"],"additional"=>["legal_entity.personal_id_number","legal_entity.verification.document"]}}
      }
    end

    def self.mock_balance(usd_balance = 10000)
      {
        object: "balance",
        available: [
          {
            currency: "usd",
            amount: usd_balance,
            source_types: {
              card: 25907032203,
              bank_account: 108476658,
              bitcoin_receiver: 1545182
            }
          }],
        instant_available: [
          {
            currency: "usd",
            amount: usd_balance,
            source_types: {
              card: 25907032203,
              bank_account: 108476658,
              bitcoin_receiver: 1545182
            }
          }],
        connect_reserved: [
          {
            currency: "usd",
            amount: 4700
          }],
        livemode: false,
        pending: [
          {
            currency: "usd",
            amount: 22738833554,
            source_types: {
              card: 22738826610,
              bank_account: 0,
              bitcoin_receiver: 6944
            }
          }]
      }
    end

    def self.mock_balance_transactions(ids=[])
      bts = {}
      ids.each do |id|
        bts[id] = self.mock_balance_transaction(id: id)
      end
      bts
    end

    def self.mock_balance_transaction(params = {})
      currency = params[:currency] || StripeMock.default_currency
      bt_id = params[:id] || 'test_txn_default'
      source = params[:source] || 'ch_test_charge'
      {
        id: bt_id,
        object: "balance_transaction",
        amount: 10000,
        available_on: 1462406400,
        created: 1461880226,
        currency: currency,
        description: nil,
        fee: 320,
        fee_details: [
          {
            amount: 320,
            application: nil,
            currency: currency,
            description: "Stripe processing fees",
            type: "stripe_fee"
          }
        ],
        net: 9680,
        source: source,
        sourced_transfers: {
          object: "list",
          data: [],
          has_more: false,
          total_count: 0,
          url: "/v1/transfers?source_transaction=#{source}"
        },
        status: "pending",
        type: "charge"
      }.merge(params)
    end

    def self.mock_subscription_item(params = {})
      id = params[:id] || 'test_si_default'
      {
        id: id,
        object: 'subscription_item',
        created: 1504716183,
        metadata: {
      },
        plan: {
          id: 'PER_USER_PLAN1',
          object: 'plan',
          amount: 1337,
          created: 1504716177,
          currency: StripeMock.default_currency,
          interval: 'month',
          interval_count: 1,
          livemode: false,
          metadata: {},
          name: 'StripeMock Default Plan ID',
          statement_descriptor: nil,
          trial_period_days: nil
        },
        quantity: 2
      }.merge(params)
    end

    def self.mock_ephemeral_key(**params)
      created = Time.now.to_i
      expires = created + 34_000
      {
        id: "ephkey_default",
        object: "ephemeral_key",
        associated_objects: [
          {
            id: params[:customer],
            type: "customer"
          }
        ],
        created: created,
        expires: expires,
        livemode: false,
        secret: "ek_test_default"
      }
    end

    def self.mock_payment_intent(params = {})
      payment_intent_id = params[:id] || "pi_1EwXFB2eZvKYlo2CggNnFBo8"
      amount = params[:amount] || 49900
      currency = params[:currency] || StripeMock.default_currency
      {
          id: payment_intent_id,
          object: "payment_intent",
          amount: amount,
          amount_capturable: 0,
          amount_received: 0,
          application: nil,
          application_fee_amount: nil,
          canceled_at: nil,
          cancellation_reason: nil,
          capture_method: "automatic",
          charges: {
              object: "list",
              data: [],
              has_more: false,
              total_count: 1,
              url: "/v1/charges?payment_intent=pi_1EwXFB2eZvKYlo2CggNnFBo8"
          },
          client_secret: "pi_1EwXFB2eZvKYlo2CggNnFBo8_secret_vOMkpqZu8ca7hxhfiO80tpT3v",
          confirmation_method: "manual",
          created: 1563208901,
          currency: currency,
          customer: nil,
          description: nil,
          invoice: nil,
          last_payment_error: nil,
          livemode: false,
          metadata: {},
          next_action: { type: "use_stripe_sdk" },
          on_behalf_of: nil,
          payment_method: nil,
          payment_method_types: [
              "card"
          ],
          receipt_email: nil,
          review: nil,
          setup_future_usage: nil,
          shipping: nil,
          source: nil,
          statement_descriptor: nil,
          status: "requires_action",
          transfer_data: nil,
          transfer_group: nil
      }.merge(params)
    end

    def self.mock_payment_method(params = {})
      payment_method_id = params[:id] || 'pm_1ExEuFL2DI6wht39WNJgbybl'

      type = params[:type].to_sym
      data = {
        card: {
          brand: 'visa',
          checks: {
            address_line1_check: nil,
            address_postal_code_check: nil,
            cvc_check: 'pass'
          },
          country: 'FR',
          exp_month: 2,
          exp_year: 2022,
          fingerprint: 'Hr3Ly5z5IYxsokWA',
          funding: 'credit',
          generated_from: nil,
          last4: '3155',
          three_d_secure_usage: { supported: true },
          wallet: nil
        },
        ideal: {
          bank: 'ing',
          bic: 'INGBNL2A',
          iban_last4: '****',
          verified_name: 'JENNY ROSEN'
        },
        sepa_debit: {
          bank_code: '37040044',
          branch_code: '',
          country: 'DE',
          fingerprint: 'FD81kbVPe7M05BMj',
          last4: '3000'
        }
      }

      {
        id: payment_method_id,
        object: 'payment_method',
        type: params[:type],
        billing_details: {
          address: {
            city: 'New Orleans',
            country: 'US',
            line1: 'Bourbon Street 23',
            line2: nil,
            postal_code: '10000',
            state: nil
          },
          email: 'foo@bar.com',
          name: 'John Dolton',
          phone: nil
        },
        customer: params[:customer] || nil,
        metadata: {
          order_id: '123456789'
        }
      }.merge(type => data[type]).merge(params)
    end

    def self.mock_setup_intent(params = {})
      setup_intent_id = params[:id] || "seti_1F96eK2aLAadsDqo0AVIyPmC"
      {
        :id => setup_intent_id,
        :object => "setup_intent",
        :application => nil,
        :cancellation_reason => nil,
        :client_secret => "seti_1F96eK2aLAadsDqo0AVIyPmC_secret_FePTYgOoPFxDOUL53fFMSoTAyiXsWAV",
        :created => 1566204936,
        :customer => nil,
        :description => nil,
        :last_setup_error => nil,
        :livemode => false,
        :metadata => {},
        :next_action => nil,
        :on_behalf_of => nil,
        :payment_method => nil,
        :payment_method_options => {
          card: {request_three_d_secure: "automatic"}
        },
        :payment_method_types => ["card"],
        :status => "requires_payment_method",
        :usage => "off_session"
      }.merge(params)
    end

    def self.mock_checkout_session(params = {})
      cs_id = params[:id] || "test_cs_default"
      currency = params[:currency] || StripeMock.default_currency
      {
        id: cs_id,
        object: 'checkout.session',
        billing_address_collection: nil,
        cancel_url: 'https://example.com/cancel',
        client_reference_id: nil,
        customer: nil,
        customer_email: nil,
        display_items: [
          {
            amount: 1500,
            currency: currency,
            custom: {
              description: 'Comfortable cotton t-shirt',
              images: nil,
              name: 'T-shirt'
            },
            quantity: 2,
            type: 'custom'
          }
        ],
        livemode: false,
        locale: nil,
        mode: nil,
        payment_intent: mock_payment_intent[:id],
        payment_method_types: [
          'card'
        ],
        setup_intent: nil,
        submit_type: nil,
        subscription: nil,
        success_url: 'https://example.com/success'
      }.merge(params)
    end
  end
end
