# frozen_string_literal: true

require 'openssl'
require 'zlib'
require 'json'
require 'rack/request'
require 'rack/response'
require 'rack/session/abstract/id'

module Rack
  module Protection
    # Rack::Protection::EncryptedCookie provides simple cookie based session management.
    # By default, the session is a Ruby Hash stored as base64 encoded marshalled
    # data set to :key (default: rack.session).  The object that encodes the
    # session data is configurable and must respond to +encode+ and +decode+.
    # Both methods must take a string and return a string.
    #
    # When the secret key is set, cookie data is checked for data integrity.
    # The old_secret key is also accepted and allows graceful secret rotation.
    # A legacy_hmac_secret is also accepted and is used to upgrade existing
    # sessions to the new encryption scheme.
    #
    # There is also a legacy_hmac_coder option which can be set if a non-default
    # coder was used for legacy session cookies.
    #
    # Example:
    #
    #     use Rack::Protection::EncryptedCookie,
    #                                :key => 'rack.session',
    #                                :domain => 'foo.com',
    #                                :path => '/',
    #                                :expire_after => 2592000,
    #                                :secret => 'change_me',
    #                                :old_secret => 'old_secret'
    #
    #     All parameters are optional.
    #
    # Example using legacy HMAC options
    #
    #   Rack::Protection:EncryptedCookie.new(application, {
    #     # The secret used for legacy HMAC cookies
    #     legacy_hmac_secret: 'legacy secret',
    #     # legacy_hmac_coder will default to Rack::Protection::EncryptedCookie::Base64::Marshal
    #     legacy_hmac_coder: Rack::Protection::EncryptedCookie::Identity.new,
    #     # legacy_hmac will default to OpenSSL::Digest::SHA1
    #     legacy_hmac: OpenSSL::Digest::SHA256
    #   })
    #
    # Example of a cookie with no encoding:
    #
    #   Rack::Protection::EncryptedCookie.new(application, {
    #     :coder => Rack::Protection::EncryptedCookie::Identity.new
    #   })
    #
    # Example of a cookie with custom encoding:
    #
    #   Rack::Protection::EncryptedCookie.new(application, {
    #     :coder => Class.new {
    #       def encode(str); str.reverse; end
    #       def decode(str); str.reverse; end
    #     }.new
    #   })
    #
    class EncryptedCookie < Rack::Session::Abstract::Persisted
      # Encode session cookies as Base64
      class Base64
        def encode(str)
          [str].pack('m0')
        end

        def decode(str)
          str.unpack1('m')
        end

        # Encode session cookies as Marshaled Base64 data
        class Marshal < Base64
          def encode(str)
            super(::Marshal.dump(str))
          end

          def decode(str)
            return unless str

            begin
              ::Marshal.load(super(str))
            rescue StandardError
              nil
            end
          end
        end

        # N.B. Unlike other encoding methods, the contained objects must be a
        # valid JSON composite type, either a Hash or an Array.
        class JSON < Base64
          def encode(obj)
            super(::JSON.dump(obj))
          end

          def decode(str)
            return unless str

            begin
              ::JSON.parse(super(str))
            rescue StandardError
              nil
            end
          end
        end

        class ZipJSON < Base64
          def encode(obj)
            super(Zlib::Deflate.deflate(::JSON.dump(obj)))
          end

          def decode(str)
            return unless str

            ::JSON.parse(Zlib::Inflate.inflate(super(str)))
          rescue StandardError
            nil
          end
        end
      end

      # Use no encoding for session cookies
      class Identity
        def encode(str); str; end
        def decode(str); str; end
      end

      class Marshal
        def encode(str)
          ::Marshal.dump(str)
        end

        def decode(str)
          ::Marshal.load(str) if str
        end
      end

      attr_reader :coder

      def initialize(app, options = {})
        # Assume keys are hex strings and convert them to raw byte strings for
        # actual key material
        @secrets = options.values_at(:secret, :old_secret).compact.map do |secret|
          [secret].pack('H*')
        end

        warn <<-MSG unless secure?(options)
        SECURITY WARNING: No secret option provided to Rack::Protection::EncryptedCookie.
        This poses a security threat. It is strongly recommended that you
        provide a secret to prevent exploits that may be possible from crafted
        cookies. This will not be supported in future versions of Rack, and
        future versions will even invalidate your existing user cookies.

        Called from: #{caller[0]}.
        MSG

        warn <<-MSG if @secrets.first && @secrets.first.length < 32
        SECURITY WARNING: Your secret is not long enough. It must be at least
        32 bytes long and securely random. To generate such a key for use
        you can run the following command:

        ruby -rsecurerandom -e 'p SecureRandom.hex(32)'

        Called from: #{caller[0]}.
        MSG

        if options.key?(:legacy_hmac_secret)
          @legacy_hmac = options.fetch(:legacy_hmac, OpenSSL::Digest::SHA1)

          # Multiply the :digest_length: by 2 because this value is the length of
          # the digest in bytes but session digest strings are encoded as hex
          # strings
          @legacy_hmac_length = @legacy_hmac.new.digest_length * 2
          @legacy_hmac_secret = options[:legacy_hmac_secret]
          @legacy_hmac_coder  = (options[:legacy_hmac_coder] ||= Base64::Marshal.new)
        else
          @legacy_hmac = false
        end

        # If encryption is used we can just use a default Marshal encoder
        # without Base64 encoding the results.
        #
        # If no encryption is used, rely on the previous default (Base64::Marshal)
        @coder = (options[:coder] ||= (@secrets.any? ? Marshal.new : Base64::Marshal.new))

        super(app, options.merge!(cookie_only: true))
      end

      private

      def find_session(req, _sid)
        data = unpacked_cookie_data(req)
        data = persistent_session_id!(data)
        [data['session_id'], data]
      end

      def extract_session_id(request)
        unpacked_cookie_data(request)['session_id']
      end

      def unpacked_cookie_data(request)
        request.fetch_header(RACK_SESSION_UNPACKED_COOKIE_DATA) do |k|
          session_data = cookie_data = request.cookies[@key]

          # Try to decrypt with the first secret, if that returns nil, try
          # with old_secret
          unless @secrets.empty?
            session_data = Rack::Protection::Encryptor.decrypt_message(cookie_data, @secrets.first)
            session_data ||= Rack::Protection::Encryptor.decrypt_message(cookie_data, @secrets[1]) if @secrets.size > 1
          end

          # If session_data is still nil, are there is a legacy HMAC
          # configured, try verify and parse the cookie that way
          if !session_data && @legacy_hmac
            digest = cookie_data.slice!(-@legacy_hmac_length..-1)
            cookie_data.slice!(-2..-1) # remove double dash
            session_data = cookie_data if digest_match?(cookie_data, digest)

            # Decode using legacy HMAC decoder
            request.set_header(k, @legacy_hmac_coder.decode(session_data) || {})
          else
            request.set_header(k, coder.decode(session_data) || {})
          end
        end
      end

      def persistent_session_id!(data, sid = nil)
        data ||= {}
        data['session_id'] ||= sid || generate_sid
        data
      end

      def write_session(req, session_id, session, _options)
        session = session.merge('session_id' => session_id)
        session_data = coder.encode(session)

        unless @secrets.empty?
          session_data = Rack::Protection::Encryptor.encrypt_message(session_data, @secrets.first)
        end

        if session_data.size > (4096 - @key.size)
          req.get_header(RACK_ERRORS).puts('Warning! Rack::Protection::EncryptedCookie data size exceeds 4K.')
          nil
        else
          session_data
        end
      end

      def delete_session(_req, _session_id, options)
        # Nothing to do here, data is in the client
        generate_sid unless options[:drop]
      end

      def digest_match?(data, digest)
        return false unless data && digest

        Rack::Utils.secure_compare(digest, generate_hmac(data))
      end

      def generate_hmac(data)
        OpenSSL::HMAC.hexdigest(@legacy_hmac.new, @legacy_hmac_secret, data)
      end

      def secure?(options)
        @secrets.size >= 1 ||
          (options[:coder] && options[:let_coder_handle_secure_encoding])
      end
    end
  end
end
