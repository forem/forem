# frozen_string_literal: true

require 'openssl'

begin
  require 'rbnacl'
rescue LoadError
  raise if defined?(RbNaCl)
end

require_relative 'jwa/hmac'
require_relative 'jwa/eddsa'
require_relative 'jwa/ecdsa'
require_relative 'jwa/rsa'
require_relative 'jwa/ps'
require_relative 'jwa/none'
require_relative 'jwa/unsupported'
require_relative 'jwa/wrapper'

module JWT
  module JWA
    ALGOS = [Hmac, Ecdsa, Rsa, Eddsa, Ps, None, Unsupported].tap do |l|
      if ::JWT.rbnacl_6_or_greater?
        require_relative 'jwa/hmac_rbnacl'
        l << Algos::HmacRbNaCl
      elsif ::JWT.rbnacl?
        require_relative 'jwa/hmac_rbnacl_fixed'
        l << Algos::HmacRbNaClFixed
      end
    end.freeze

    class << self
      def find(algorithm)
        indexed[algorithm&.downcase]
      end

      def create(algorithm)
        return algorithm if JWA.implementation?(algorithm)

        Wrapper.new(*find(algorithm))
      end

      def implementation?(algorithm)
        (algorithm.respond_to?(:valid_alg?) && algorithm.respond_to?(:verify)) ||
          (algorithm.respond_to?(:alg) && algorithm.respond_to?(:sign))
      end

      private

      def indexed
        @indexed ||= begin
          fallback = [nil, Unsupported]
          ALGOS.each_with_object(Hash.new(fallback)) do |cls, hash|
            cls.const_get(:SUPPORTED).each do |alg|
              hash[alg.downcase] = [alg, cls]
            end
          end
        end
      end
    end
  end
end
