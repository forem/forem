require "anyway_config"

require "imgproxy/url_adapters"

module Imgproxy
  # Imgproxy config
  #
  # @!attribute endpoint
  #   imgproxy endpoint
  #   @return [String]
  # @!attribute key
  #   imgproxy hex-encoded signature key
  #   @return [String]
  # @!attribute salt
  #   imgproxy hex-encoded signature salt
  #   @return [String]
  # @!attribute raw_key
  #   Decoded signature key
  #   @return [String]
  # @!attribute raw_salt
  #   Decoded signature salt
  #   @return [String]
  # @!attribute signature_size
  #   imgproxy signature size. Defaults to 32
  #   @return [String]
  # @!attribute use_short_options
  #   Use short processing option names (+rs+ for +resize+, +g+ for +gravity+, etc).
  #   Defaults to true
  #   @return [String]
  # @!attribute base64_encode_urls
  #   Base64 encode the URL. Defaults to false
  #   @return [String]
  # @!attribute always_escape_plain_urls
  #   Always escape plain URLs. Defaults to false
  #   @return [String]
  # @!attribute use_s3_urls
  #   Use short S3 urls (s3://...) when possible. Defaults to false
  #   @return [String]
  # @!attribute use_gcs_urls
  #   Use short Google Cloud Storage urls (gs://...) when possible. Defaults to false
  #   @return [String]
  # @!attribute gcs_bucket
  #   Google Cloud Storage bucket name
  #   @return [String]
  # @!attribute shrine_host
  #   Shrine host
  #   @return [String]
  #
  # @see Imgproxy.configure
  # @see https://github.com/palkan/anyway_config anyway_config
  class Config < Anyway::Config
    attr_config(
      :endpoint,
      :key,
      :salt,
      :raw_key,
      :raw_salt,
      signature_size: 32,
      use_short_options: true,
      base64_encode_urls: false,
      always_escape_plain_urls: false,
      use_s3_urls: false,
      use_gcs_urls: false,
      gcs_bucket: nil,
      shrine_host: nil,
    )

    alias_method :set_key, :key=
    alias_method :set_raw_key, :raw_key=
    alias_method :set_salt, :salt=
    alias_method :set_raw_salt, :raw_salt=
    private :set_key, :set_raw_key, :set_salt, :set_raw_salt

    def key=(value)
      value = value&.to_s
      super(value)
      set_raw_key(value && [value].pack("H*"))
    end

    def raw_key=(value)
      value = value&.to_s
      super(value)
      set_key(value&.unpack("H*")&.first)
    end

    def salt=(value)
      value = value&.to_s
      super(value)
      set_raw_salt(value && [value].pack("H*"))
    end

    def raw_salt=(value)
      value = value&.to_s
      super(value)
      set_salt(value&.unpack("H*")&.first)
    end

    # @deprecated Please use {#key} instead
    def hex_key=(value)
      warn "[DEPRECATION] #hex_key is deprecated. Please use #key instead."
      self.key = value
    end

    # @deprecated Please use {#salt} instead
    def hex_salt=(value)
      warn "[DEPRECATION] #hex_salt is deprecated. Please use #salt instead."
      self.salt = value
    end

    # URL adapters config. Allows to use this gem with ActiveStorage, Shrine, etc.
    #
    #   Imgproxy.configure do |config|
    #     config.url_adapters.add Imgproxy::UrlAdapters::ActiveStorage.new
    #   end
    #
    #   Imgproxy.url_for(user.avatar)
    #
    # @return [Imgproxy::UrlAdapters]
    # @see Imgproxy::UrlAdapters
    def url_adapters
      @url_adapters ||= Imgproxy::UrlAdapters.new
    end
  end
end
