module Liquid
  class Raw < Block
    remove_const(:FullTokenPossiblyInvalid) if defined?(FullTokenPossiblyInvalid)
    FullTokenPossiblyInvalid = /\A(.*)#{TagStart}\s*(\w+)\s*#{TagEnd}\z/om # rubocop:disable Naming/ConstantName
  end

  Template.register_tag("raw", Raw)
end
