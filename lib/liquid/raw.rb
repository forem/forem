# Patches Liquid::Raw to change `FullTokenPossiblyInvalid` regexp
# see https://github.com/Shopify/liquid/blob/master/lib/liquid/tags/raw.rb

module Liquid
  class Raw < Block
    remove_const(:FullTokenPossiblyInvalid) if defined?(FullTokenPossiblyInvalid)
    FullTokenPossiblyInvalid = /\A(.*)#{TagStart}\s*(\w+)\s*#{TagEnd}\z/om # rubocop:disable Naming/ConstantName
  end

  Template.register_tag("raw", Raw)
end
