# frozen_string_literal: true

require 'countries'

# Some apps might not want to constantly call +ISO3166::Country+. This gem has a helper that can provide a Country class
#
# With global Country Helper enabled
#
#   c = Country['US']
#
# This will conflict with any existing Country constant
#
# To Use
#
#   gem 'countries', require: 'countries/global'
#
class Country < ISO3166::Country
end
