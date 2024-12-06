# frozen_string_literal: true

require 'money'

module ISO3166
  # Optional extension which allows you to get back a +Money::Currency+ object with all the currency info.
  # This requires enabling the integration with the {Money}[https://github.com/RubyMoney/money] gem (See {ISO3166::Configuration#enable_currency_extension!})
  module CountryCurrencyMethods
    # @return [Money::Currency] The currency data for this Country's +currency_code+
    def currency
      Money::Currency.find(data['currency_code'])
    end
  end
end
