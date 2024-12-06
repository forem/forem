# frozen_string_literal: true

module JWT
  class EncodeError < StandardError; end
  class DecodeError < StandardError; end
  class RequiredDependencyError < StandardError; end

  class VerificationError < DecodeError; end
  class ExpiredSignature < DecodeError; end
  class IncorrectAlgorithm < DecodeError; end
  class ImmatureSignature < DecodeError; end
  class InvalidIssuerError < DecodeError; end
  class UnsupportedEcdsaCurve < IncorrectAlgorithm; end
  class InvalidIatError < DecodeError; end
  class InvalidAudError < DecodeError; end
  class InvalidSubError < DecodeError; end
  class InvalidJtiError < DecodeError; end
  class InvalidPayload < DecodeError; end
  class MissingRequiredClaim < DecodeError; end
  class Base64DecodeError < DecodeError; end

  class JWKError < DecodeError; end
end
