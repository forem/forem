require "openssl"
require "base64"
require "erb"

require "imgproxy/options"
require "imgproxy/options_aliases"

module Imgproxy
  # Builds imgproxy URL
  #
  #   builder = Imgproxy::Builder.new(
  #     width: 500,
  #     height: 400,
  #     resizing_type: :fill,
  #     sharpen: 0.5
  #   )
  #
  #   builder.url_for("http://images.example.com/images/image1.jpg")
  #   builder.url_for("http://images.example.com/images/image2.jpg")
  class Builder
    # @param [Hash] options Processing options
    # @see Imgproxy.url_for
    def initialize(options = {})
      options = options.dup

      extract_builder_options(options)

      @options = Imgproxy::Options.new(options)
      @format = @options.delete(:format)
    end

    # Genrates imgproxy URL
    #
    # @return [String] imgproxy URL
    # @param [String,URI, Object] image Source image URL or object applicable for
    #   the configured URL adapters
    # @see Imgproxy.url_for
    def url_for(image)
      path = [*processing_options, url(image, ext: @format)].join("/")
      signature = sign_path(path)

      File.join(Imgproxy.config.endpoint.to_s, signature, path)
    end

    # Genrates imgproxy info URL
    #
    # @return [String] imgproxy info URL
    # @param [String,URI, Object] image Source image URL or object applicable for
    #   the configured URL adapters
    # @see Imgproxy.info_url_for
    def info_url_for(image)
      path = url(image)
      signature = sign_path(path)

      File.join(Imgproxy.config.endpoint.to_s, "info", signature, path)
    end

    private

    NEED_ESCAPE_RE = /[@?% ]|[^\p{Ascii}]/.freeze

    def extract_builder_options(options)
      @use_short_options = not_nil_or(options.delete(:use_short_options), config.use_short_options)
      @base64_encode_url = not_nil_or(options.delete(:base64_encode_url), config.base64_encode_urls)
      @escape_plain_url =
        not_nil_or(options.delete(:escape_plain_url), config.always_escape_plain_urls)
    end

    def processing_options
      @processing_options ||= @options.map do |key, value|
        [option_alias(key), value].join(":")
      end
    end

    def url(image, ext: nil)
      url = config.url_adapters.url_of(image)

      @base64_encode_url ? base64_url_for(url, ext: ext) : plain_url_for(url, ext: ext)
    end

    def plain_url_for(url, ext: nil)
      escaped_url = need_escape_url?(url) ? ERB::Util.url_encode(url) : url

      ext ? "plain/#{escaped_url}@#{ext}" : "plain/#{escaped_url}"
    end

    def base64_url_for(url, ext: nil)
      encoded_url = Base64.urlsafe_encode64(url).tr("=", "").scan(/.{1,16}/).join("/")

      ext ? "#{encoded_url}.#{ext}" : encoded_url
    end

    def need_escape_url?(url)
      @escape_plain_url || url.match?(NEED_ESCAPE_RE)
    end

    def option_alias(name)
      return name unless @use_short_options

      Imgproxy::OPTIONS_ALIASES.fetch(name, name)
    end

    def sign_path(path)
      return "unsafe" unless ready_to_sign?

      digest = OpenSSL::HMAC.digest(
        OpenSSL::Digest.new("sha256"),
        signature_key,
        "#{signature_salt}/#{path}",
      )[0, signature_size]

      Base64.urlsafe_encode64(digest).tr("=", "")
    end

    def ready_to_sign?
      !(signature_key.nil? || signature_salt.nil? ||
        signature_key.empty? || signature_salt.empty?)
    end

    def signature_key
      config.raw_key
    end

    def signature_salt
      config.raw_salt
    end

    def signature_size
      config.signature_size
    end

    def config
      Imgproxy.config
    end

    def not_nil_or(value, fallback)
      value.nil? ? fallback : value
    end
  end
end
