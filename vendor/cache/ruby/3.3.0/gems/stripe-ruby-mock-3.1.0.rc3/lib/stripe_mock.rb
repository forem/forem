require 'ostruct'
require 'multi_json'
require 'dante'
require 'time'

require 'stripe'

require 'stripe_mock/version'
require 'stripe_mock/util'
require 'stripe_mock/error_queue'

require 'stripe_mock/data'
require 'stripe_mock/data/list'

require 'stripe_mock/errors/stripe_mock_error'
require 'stripe_mock/errors/unsupported_request_error'
require 'stripe_mock/errors/uninitialized_instance_error'
require 'stripe_mock/errors/unstarted_state_error'
require 'stripe_mock/errors/server_timeout_error'
require 'stripe_mock/errors/closed_client_connection_error'

require 'stripe_mock/client'
require 'stripe_mock/server'

require 'stripe_mock/api/instance'
require 'stripe_mock/api/client'
require 'stripe_mock/api/server'

require 'stripe_mock/api/bank_tokens'
require 'stripe_mock/api/account_balance'
require 'stripe_mock/api/conversion_rate'
require 'stripe_mock/api/card_tokens'
require 'stripe_mock/api/debug'
require 'stripe_mock/api/errors'
require 'stripe_mock/api/global_id_prefix'
require 'stripe_mock/api/live'
require 'stripe_mock/api/test_helpers'
require 'stripe_mock/api/webhooks'

require 'stripe_mock/request_handlers/helpers/bank_account_helpers.rb'
require 'stripe_mock/request_handlers/helpers/external_account_helpers.rb'
require 'stripe_mock/request_handlers/helpers/card_helpers.rb'
require 'stripe_mock/request_handlers/helpers/charge_helpers.rb'
require 'stripe_mock/request_handlers/helpers/coupon_helpers.rb'
require 'stripe_mock/request_handlers/helpers/subscription_helpers.rb'
require 'stripe_mock/request_handlers/helpers/token_helpers.rb'

require 'stripe_mock/request_handlers/validators/param_validators.rb'

require 'stripe_mock/request_handlers/account_links.rb'
require 'stripe_mock/request_handlers/express_login_links.rb'
require 'stripe_mock/request_handlers/accounts.rb'
require 'stripe_mock/request_handlers/external_accounts.rb'
require 'stripe_mock/request_handlers/balance.rb'
require 'stripe_mock/request_handlers/balance_transactions.rb'
require 'stripe_mock/request_handlers/charges.rb'
require 'stripe_mock/request_handlers/cards.rb'
require 'stripe_mock/request_handlers/sources.rb'
require 'stripe_mock/request_handlers/customers.rb'
require 'stripe_mock/request_handlers/coupons.rb'
require 'stripe_mock/request_handlers/disputes.rb'
require 'stripe_mock/request_handlers/events.rb'
require 'stripe_mock/request_handlers/invoices.rb'
require 'stripe_mock/request_handlers/invoice_items.rb'
require 'stripe_mock/request_handlers/orders.rb'
require 'stripe_mock/request_handlers/plans.rb'
require 'stripe_mock/request_handlers/prices.rb'
require 'stripe_mock/request_handlers/recipients.rb'
require 'stripe_mock/request_handlers/refunds.rb'
require 'stripe_mock/request_handlers/transfers.rb'
require 'stripe_mock/request_handlers/payment_intents.rb'
require 'stripe_mock/request_handlers/payment_methods.rb'
require 'stripe_mock/request_handlers/setup_intents.rb'
require 'stripe_mock/request_handlers/payouts.rb'
require 'stripe_mock/request_handlers/subscriptions.rb'
require 'stripe_mock/request_handlers/subscription_items.rb'
require 'stripe_mock/request_handlers/tokens.rb'
require 'stripe_mock/request_handlers/country_spec.rb'
require 'stripe_mock/request_handlers/ephemeral_key.rb'
require 'stripe_mock/request_handlers/products.rb'
require 'stripe_mock/request_handlers/tax_rates.rb'
require 'stripe_mock/request_handlers/checkout.rb'
require 'stripe_mock/request_handlers/checkout_session.rb'
require 'stripe_mock/instance'

require 'stripe_mock/test_strategies/base.rb'
require 'stripe_mock/test_strategies/mock.rb'
require 'stripe_mock/test_strategies/live.rb'

module StripeMock

  @default_currency = 'usd'
  lib_dir = File.expand_path(File.dirname(__FILE__), '../..')
  @webhook_fixture_path = './spec/fixtures/stripe_webhooks/'
  @webhook_fixture_fallback_path = File.join(lib_dir, 'stripe_mock/webhook_fixtures')

  class << self
    attr_accessor :default_currency
    attr_accessor :webhook_fixture_path
  end
end
