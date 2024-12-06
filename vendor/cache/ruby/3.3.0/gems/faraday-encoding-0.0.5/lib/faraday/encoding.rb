require "faraday"

module Faraday
  class Faraday::Encoding < Faraday::Middleware
    def self.mappings
      {
        'utf8' => 'utf-8'
      }
    end

    def call(environment)
      @app.call(environment).on_complete do |env|
        @env = env
        if encoding = content_charset
          env[:body] = env[:body].dup if env[:body].frozen?
          env[:body].force_encoding(encoding)
        end
      end
    end

    private

    # @return [Encoding|NilClass] returns Encoding or nil
    def content_charset
      ::Encoding.find encoding_name rescue nil
    end

    # @return [String] returns a string representing encoding name if it is find in the CONTENT TYPE header
    def encoding_name
      if /charset=([^;|$]+)/.match(content_type)
        mapped_encoding(Regexp.last_match(1))
      end
    end

    # @param [String] encoding_name
    # @return [String] tries to find a mapping for the encoding name
    # ex: returns 'utf-8' for encoding_name 'utf8'
    # if mapping is not found - return the same input parameter `encoding_name`
    # Look at `self.mappings` to see which mappings are available
    def mapped_encoding(encoding_name)
      self.class.mappings.fetch(encoding_name, encoding_name)
    end

    # @return [String]
    def content_type
      @env[:response_headers][:content_type]
    end
  end
end

Faraday::Response.register_middleware encoding: Faraday::Encoding
