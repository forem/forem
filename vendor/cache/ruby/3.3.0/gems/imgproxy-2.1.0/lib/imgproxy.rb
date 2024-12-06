require "imgproxy/version"
require "imgproxy/config"
require "imgproxy/builder"

require "imgproxy/extensions/active_storage"
require "imgproxy/extensions/shrine"

# @see Imgproxy::ClassMethods
module Imgproxy
  class << self
    # Imgproxy config
    #
    # @return [Config]
    def config
      @config ||= Imgproxy::Config.new
    end

    # Yields Imgproxy config
    #
    #   Imgproxy.configure do |config|
    #     config.endpoint = "http://imgproxy.example.com"
    #     config.key = "your_key"
    #     config.salt = "your_salt"
    #     config.use_short_options = true
    #   end
    #
    # @yieldparam config [Config]
    # @return [Config]
    def configure
      yield config
      config
    end

    # Genrates imgproxy URL
    #
    #   Imgproxy.url_for(
    #     "http://images.example.com/images/image.jpg",
    #     width: 500,
    #     height: 400,
    #     resizing_type: :fill,
    #     sharpen: 0.5,
    #     gravity: {
    #       type: :soea,
    #       x_offset: 10,
    #       y_offset: 5,
    #     },
    #     crop: {
    #       width: 2000,
    #       height: 1000,
    #       gravity: {
    #         type: :nowe,
    #         x_offset: 20,
    #         y_offset: 30,
    #       },
    #     },
    #   )
    #
    # @return [String] imgproxy URL
    # @param [String,URI, Object] image Source image URL or object applicable for
    #   the configured URL adapters
    # @param [Hash] options Processing options
    # @option options [Hash|Array|String] :resize
    # @option options [Hash|Array|String] :size
    # @option options [String] :resizing_type
    # @option options [String] :resizing_algorithm supported only by imgproxy pro
    # @option options [Integer] :width
    # @option options [Integer] :height
    # @option options [Float] :dpr
    # @option options [Boolean] :enlarge
    # @option options [Hash|Array|Boolean|String] :extend
    # @option options [Hash|Array|String] :gravity
    # @option options [Hash|Array|String] :crop
    # @option options [Array] :padding
    # @option options [Hash|Array|String] :trim
    # @option options [Integer] :rotate
    # @option options [Integer] :quality
    # @option options [Integer] :max_bytes
    # @option options [Array|String] :background
    # @option options [Float] :background_alpha supported only by imgproxy pro
    # @option options [Hash|Array|String] :adjust
    # @option options [Integer] :brightness supported only by imgproxy pro
    # @option options [Float] :contrast supported only by imgproxy pro
    # @option options [Float] :saturation supported only by imgproxy pro
    # @option options [Float] :blur
    # @option options [Float] :sharpen
    # @option options [Integer] :pixelate supported only by imgproxy pro
    # @option options [String] :unsharpening supported only by imgproxy pro
    # @option options [Hash|Array|Float|String] :watermark
    # @option options [String] :watermark_url supported only by imgproxy pro
    # @option options [String] :style supported only by imgproxy pro
    # @option options [Hash|Array|String] :jpeg_options supported only by imgproxy pro
    # @option options [Hash|Array|String] :png_options supported only by imgproxy pro
    # @option options [Hash|Array|String] :gif_options supported only by imgproxy pro
    # @option options [Integer] :page supported only by imgproxy pro
    # @option options [Integer] :video_thumbnail_second supported only by imgproxy pro
    # @option options [Array] :preset
    # @option options [String] :cachebuster
    # @option options [Boolean] :strip_metadata
    # @option options [Boolean] :strip_color_profile
    # @option options [Boolean] :auto_rotate
    # @option options [String] :filename
    # @option options [String] :format
    # @option options [Boolean] :return_attachment
    # @option options [Integer] :expires
    # @option options [Boolean] :use_short_options
    # @option options [Boolean] :base64_encode_urls
    # @option options [Boolean] :escape_plain_url
    # @see https://docs.imgproxy.net/#/generating_the_url_advanced?id=processing-options
    #   Available imgproxy URL processing options and their arguments
    def url_for(image, options = {})
      Imgproxy::Builder.new(options).url_for(image)
    end

    # Genrates imgproxy info URL. Supported only by imgproxy pro
    #
    #   Imgproxy.info_url_for("http://images.example.com/images/image.jpg")
    #
    # @return [String] imgproxy info URL
    # @param [String,URI, Object] image Source image URL or object applicable for
    #   the configured URL adapters
    # @param [Hash] options Processing options
    # @option options [Boolean] :base64_encode_urls
    # @option options [Boolean] :escape_plain_url
    def info_url_for(image, options = {})
      Imgproxy::Builder.new(options).info_url_for(image)
    end

    # Extends +ActiveStorage::Blob+ with {Imgproxy::Extensions::ActiveStorage.imgproxy_url} method
    # and adds URL adapters for ActiveStorage
    def extend_active_storage!
      return unless defined?(ActiveSupport) && ActiveSupport.respond_to?(:on_load)

      ActiveSupport.on_load(:active_storage_blob) do
        ::ActiveStorage::Blob.include Imgproxy::Extensions::ActiveStorage
        Imgproxy.config.url_adapters.add(Imgproxy::UrlAdapters::ActiveStorage.new)
      end
    end

    # Extends +Shrine::UploadedFile+ with {Imgproxy::Extensions::Shrine.imgproxy_url} method
    # and adds URL adapters for Shrine
    def extend_shrine!
      return unless defined?(::Shrine::UploadedFile)

      ::Shrine::UploadedFile.include Imgproxy::Extensions::Shrine
      Imgproxy.config.url_adapters.add(Imgproxy::UrlAdapters::Shrine.new)
    end
  end
end

Imgproxy.extend_active_storage!
Imgproxy.extend_shrine!
