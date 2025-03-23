# Disables regular Liquid::Variables like {{ user.name }}
# see https://github.com/Shopify/liquid/blob/master/lib/liquid/variable.rb
module Liquid
  class Variable
    def initialize(markup, _parse_context)
      # Store the original markup (e.g., {{ user.name }}) as raw text
      @markup = markup
    end

    def render(_context)
      # Return the original markup instead of processing it
      "{{#{@markup}}}"
    end
  end
end