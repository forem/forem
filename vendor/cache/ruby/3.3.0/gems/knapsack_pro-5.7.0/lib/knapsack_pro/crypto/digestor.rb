# frozen_string_literal: true

module KnapsackPro
  module Crypto
    class Digestor
      def self.salt_hexdigest(str_to_encrypt)
        salt = KnapsackPro::Config::Env.salt
        str = salt + str_to_encrypt
        Digest::SHA2.hexdigest(str)
      end
    end
  end
end
