# frozen_string_literal: true

require 'json'

require 'jwt/verify'
require 'jwt/x5c_key_finder'

# JWT::Decode module
module JWT
  # Decoding logic for JWT
  class Decode
    def initialize(jwt, key, verify, options, &keyfinder)
      raise(JWT::DecodeError, 'Nil JSON web token') unless jwt

      @jwt = jwt
      @key = key
      @options = options
      @segments = jwt.split('.')
      @verify = verify
      @signature = ''
      @keyfinder = keyfinder
    end

    def decode_segments
      validate_segment_count!
      if @verify
        decode_signature
        verify_algo
        set_key
        verify_signature
        verify_claims
      end
      raise(JWT::DecodeError, 'Not enough or too many segments') unless header && payload

      [payload, header]
    end

    private

    def verify_signature
      return unless @key || @verify

      return if none_algorithm?

      raise JWT::DecodeError, 'No verification key available' unless @key

      return if Array(@key).any? { |key| verify_signature_for?(key) }

      raise(JWT::VerificationError, 'Signature verification failed')
    end

    def verify_algo
      raise(JWT::IncorrectAlgorithm, 'An algorithm must be specified') if allowed_algorithms.empty?
      raise(JWT::IncorrectAlgorithm, 'Token is missing alg header') unless alg_in_header
      raise(JWT::IncorrectAlgorithm, 'Expected a different algorithm') if allowed_and_valid_algorithms.empty?
    end

    def set_key
      @key = find_key(&@keyfinder) if @keyfinder
      @key = ::JWT::JWK::KeyFinder.new(jwks: @options[:jwks], allow_nil_kid: @options[:allow_nil_kid]).key_for(header['kid']) if @options[:jwks]
      if (x5c_options = @options[:x5c])
        @key = X5cKeyFinder.new(x5c_options[:root_certificates], x5c_options[:crls]).from(header['x5c'])
      end
    end

    def verify_signature_for?(key)
      allowed_and_valid_algorithms.any? do |alg|
        alg.verify(data: signing_input, signature: @signature, verification_key: key)
      end
    end

    def allowed_and_valid_algorithms
      @allowed_and_valid_algorithms ||= allowed_algorithms.select { |alg| alg.valid_alg?(alg_in_header) }
    end

    # Order is very important - first check for string keys, next for symbols
    ALGORITHM_KEYS = ['algorithm',
                      :algorithm,
                      'algorithms',
                      :algorithms].freeze

    def given_algorithms
      ALGORITHM_KEYS.each do |alg_key|
        alg = @options[alg_key]
        return Array(alg) if alg
      end
      []
    end

    def allowed_algorithms
      @allowed_algorithms ||= resolve_allowed_algorithms
    end

    def resolve_allowed_algorithms
      algs = given_algorithms.map { |alg| JWA.create(alg) }

      sort_by_alg_header(algs)
    end

    # Move algorithms matching the JWT alg header to the beginning of the list
    def sort_by_alg_header(algs)
      return algs if algs.size <= 1

      algs.partition { |alg| alg.valid_alg?(alg_in_header) }.flatten
    end

    def find_key(&keyfinder)
      key = (keyfinder.arity == 2 ? yield(header, payload) : yield(header))
      # key can be of type [string, nil, OpenSSL::PKey, Array]
      return key if key && !Array(key).empty?

      raise JWT::DecodeError, 'No verification key available'
    end

    def verify_claims
      Verify.verify_claims(payload, @options)
      Verify.verify_required_claims(payload, @options)
    end

    def validate_segment_count!
      return if segment_length == 3
      return if !@verify && segment_length == 2 # If no verifying required, the signature is not needed
      return if segment_length == 2 && none_algorithm?

      raise(JWT::DecodeError, 'Not enough or too many segments')
    end

    def segment_length
      @segments.count
    end

    def none_algorithm?
      alg_in_header == 'none'
    end

    def decode_signature
      @signature = ::JWT::Base64.url_decode(@segments[2] || '')
    end

    def alg_in_header
      header['alg']
    end

    def header
      @header ||= parse_and_decode @segments[0]
    end

    def payload
      @payload ||= parse_and_decode @segments[1]
    end

    def signing_input
      @segments.first(2).join('.')
    end

    def parse_and_decode(segment)
      JWT::JSON.parse(::JWT::Base64.url_decode(segment))
    rescue ::JSON::ParserError
      raise JWT::DecodeError, 'Invalid segment encoding'
    end
  end
end
