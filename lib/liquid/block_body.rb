# Disables {% liquid %} tag introduced in version 5.0
# see <https://github.com/Shopify/liquid/blob/master/lib/liquid/block_body.rb>

module LiquidBlockBodyExtensions
  # parse_for_liquid_tag is a private method, thus we use prepend to patch it
  def parse_for_liquid_tag(_tokenizer, _parse_context)
    raise StandardError, "Liquid 'liquid' tag is disabled"
  end
end

module Liquid
  class BlockBody
    prepend LiquidBlockBodyExtensions
  end
end
