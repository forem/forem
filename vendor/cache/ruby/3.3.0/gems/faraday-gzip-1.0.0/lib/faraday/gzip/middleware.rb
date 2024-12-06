# frozen_string_literal: true

require 'zlib'

module Faraday
  module Gzip
    # Middleware to automatically decompress response bodies. If the
    # "Accept-Encoding" header wasn't set in the request, this sets it to
    # "gzip,deflate" and appropriately handles the compressed response from the
    # server. This resembles what Ruby 1.9+ does internally in Net::HTTP#get.
    # Based on https://github.com/lostisland/faraday_middleware/blob/main/lib/faraday_middleware/gzip.rb

    class Middleware < Faraday::Middleware
      def self.optional_dependency(lib = nil)
        lib ? require(lib) : yield
        true
      rescue LoadError, NameError
        false
      end

      BROTLI_SUPPORTED = optional_dependency 'brotli'

      def self.supported_encodings
        encodings = %w[gzip deflate]
        encodings << 'br' if BROTLI_SUPPORTED
        encodings
      end

      ACCEPT_ENCODING = 'Accept-Encoding'
      CONTENT_ENCODING = 'Content-Encoding'
      CONTENT_LENGTH = 'Content-Length'
      SUPPORTED_ENCODINGS = supported_encodings.join(',').freeze

      def call(env)
        env[:request_headers][ACCEPT_ENCODING] ||= SUPPORTED_ENCODINGS
        @app.call(env).on_complete do |response_env|
          if response_env[:body].empty?
            reset_body(response_env) { |body| raw_body(body) }
          else
            case response_env[:response_headers][CONTENT_ENCODING]
            when 'gzip'
              reset_body(response_env) { |body| uncompress_gzip(body) }
            when 'deflate'
              reset_body(response_env) { |body| inflate(body) }
            when 'br'
              reset_body(response_env) { |body| brotli_inflate(body) }
            end
          end
        end
      end

      def reset_body(env)
        env[:body] = yield(env[:body])
        env[:response_headers].delete(CONTENT_ENCODING)
        env[:response_headers][CONTENT_LENGTH] = env[:body].length
      end

      def uncompress_gzip(body)
        io = StringIO.new(body)
        gzip_reader = Zlib::GzipReader.new(io, encoding: 'ASCII-8BIT')
        gzip_reader.read
      end

      def inflate(body)
        # Inflate as a DEFLATE (RFC 1950+RFC 1951) stream
        Zlib::Inflate.inflate(body)
      rescue Zlib::DataError
        # Fall back to inflating as a "raw" deflate stream which
        # Microsoft servers return
        inflate = Zlib::Inflate.new(-Zlib::MAX_WBITS)
        begin
          inflate.inflate(body)
        ensure
          inflate.close
        end
      end

      def brotli_inflate(body)
        Brotli.inflate(body)
      end

      def raw_body(body)
        body
      end
    end
  end
end
