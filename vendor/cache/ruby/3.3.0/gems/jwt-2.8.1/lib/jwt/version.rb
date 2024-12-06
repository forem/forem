# frozen_string_literal: true

# Moments version builder module
module JWT
  def self.gem_version
    Gem::Version.new VERSION::STRING
  end

  # Moments version builder module
  module VERSION
    # major version
    MAJOR = 2
    # minor version
    MINOR = 8
    # tiny version
    TINY  = 1
    # alpha, beta, etc. tag
    PRE   = nil

    # Build version string
    STRING = [MAJOR, MINOR, TINY, PRE].compact.join('.')
  end

  def self.openssl_3?
    return false if OpenSSL::OPENSSL_VERSION.include?('LibreSSL')

    true if 3 * 0x10000000 <= OpenSSL::OPENSSL_VERSION_NUMBER
  end

  def self.rbnacl?
    defined?(::RbNaCl)
  end

  def self.rbnacl_6_or_greater?
    rbnacl? && ::Gem::Version.new(::RbNaCl::VERSION) >= ::Gem::Version.new('6.0.0')
  end

  def self.openssl_3_hmac_empty_key_regression?
    openssl_3? && openssl_version <= ::Gem::Version.new('3.0.0')
  end

  def self.openssl_version
    @openssl_version ||= ::Gem::Version.new(OpenSSL::VERSION)
  end
end
