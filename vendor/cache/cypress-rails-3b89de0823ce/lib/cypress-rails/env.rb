module CypressRails
  module Env
    def self.fetch(name, type: :string, default: nil)
      return default unless ENV.key?(name)

      if type == :boolean
        no_like_flag = ["", "0", "n", "no", "false"].include?(ENV.fetch(name))
        !no_like_flag
      else
        ENV.fetch(name)
      end
    end
  end
end
