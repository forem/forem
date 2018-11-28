module Liquid
  class Raw < Block
    FullTokenPossiblyInvalid = /\A(.*)#{TagStart}\s*(\w+)\s*#{TagEnd}\z/om
  end

  Template.register_tag("raw", Raw)
end
