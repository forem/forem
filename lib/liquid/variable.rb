# Disables regular Liquid::Variables like {{ user.name }}
# see https://github.com/Shopify/liquid/blob/master/lib/liquid/variable.rb
module Liquid
  class Variable
    def initialize(_markup, _parse_context)
      raise StandardError, "Liquid variables are disabled"
    end
  end
end
