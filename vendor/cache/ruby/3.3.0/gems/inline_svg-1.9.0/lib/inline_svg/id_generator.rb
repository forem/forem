require 'digest'

module InlineSvg
  class IdGenerator
    class Randomness
      require "securerandom"
      def self.call
        SecureRandom.hex(10)
      end
    end

    def self.generate(base, salt, randomness: Randomness)
      bytes = Digest::SHA1.digest("#{base}-#{salt}-#{randomness.call}")
      'a' + Digest.hexencode(bytes).to_i(16).to_s(36)
    end
  end
end
