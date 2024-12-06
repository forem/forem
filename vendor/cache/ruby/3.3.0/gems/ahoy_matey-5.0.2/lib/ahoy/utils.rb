module Ahoy
  module Utils
    def self.ensure_utf8(str)
      str.encode("UTF-8", "binary", invalid: :replace, undef: :replace, replace: "") if str
    end
  end
end
