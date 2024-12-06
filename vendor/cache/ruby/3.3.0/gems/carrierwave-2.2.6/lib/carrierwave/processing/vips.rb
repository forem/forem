module CarrierWave

  ##
  # This module simplifies manipulation with vips by providing a set
  # of convenient helper methods. If you want to use them, you'll need to
  # require this file:
  #
  #     require 'carrierwave/processing/vips'
  #
  # And then include it in your uploader:
  #
  #     class MyUploader < CarrierWave::Uploader::Base
  #       include CarrierWave::Vips
  #     end
  #
  # You can now use the provided helpers:
  #
  #     class MyUploader < CarrierWave::Uploader::Base
  #       include CarrierWave::Vips
  #
  #       process :resize_to_fit => [200, 200]
  #     end
  #
  # Or create your own helpers with the powerful vips! method, which
  # yields an ImageProcessing::Builder object. Check out the ImageProcessing
  # docs at http://github.com/janko-m/image_processing and the list of all
  # available Vips options at
  # https://libvips.github.io/libvips/API/current/using-cli.html for more info.
  #
  #     class MyUploader < CarrierWave::Uploader::Base
  #       include CarrierWave::Vips
  #
  #       process :radial_blur => 10
  #
  #       def radial_blur(amount)
  #         vips! do |builder|
  #           builder.radial_blur(amount)
  #           builder = yield(builder) if block_given?
  #           builder
  #         end
  #       end
  #     end
  #
  # === Note
  #
  # The ImageProcessing gem uses ruby-vips, a binding for the vips image
  # library. You can find more information here:
  #
  # https://github.com/libvips/ruby-vips
  #
  #
  module Vips
    extend ActiveSupport::Concern

    included do
      require "image_processing/vips"
      # We need to disable caching since we're editing images in place.
      ::Vips.cache_set_max(0)
    end

    module ClassMethods
      def convert(format)
        process :convert => format
      end

      def resize_to_limit(width, height)
        process :resize_to_limit => [width, height]
      end

      def resize_to_fit(width, height)
        process :resize_to_fit => [width, height]
      end

      def resize_to_fill(width, height, gravity='centre')
        process :resize_to_fill => [width, height, gravity]
      end

      def resize_and_pad(width, height, background=nil, gravity='centre', alpha=nil)
        process :resize_and_pad => [width, height, background, gravity, alpha]
      end
    end

    ##
    # Changes the image encoding format to the given format
    #
    # See https://libvips.github.io/libvips/API/current/using-cli.html#using-command-line-conversion
    #
    # === Parameters
    #
    # [format (#to_s)] an abbreviation of the format
    #
    # === Yields
    #
    # [Vips::Image] additional manipulations to perform
    #
    # === Examples
    #
    #     image.convert(:png)
    #
    def convert(format, page=nil)
      vips! do |builder|
        builder = builder.convert(format)
        builder = builder.loader(page: page) if page
        builder
      end
    end

    ##
    # Resize the image to fit within the specified dimensions while retaining
    # the original aspect ratio. Will only resize the image if it is larger than the
    # specified dimensions. The resulting image may be shorter or narrower than specified
    # in the smaller dimension but will not be larger than the specified values.
    #
    # === Parameters
    #
    # [width (Integer)] the width to scale the image to
    # [height (Integer)] the height to scale the image to
    # [combine_options (Hash)] additional Vips options to apply before resizing
    #
    # === Yields
    #
    # [Vips::Image] additional manipulations to perform
    #
    def resize_to_limit(width, height, combine_options: {})
      width, height = resolve_dimensions(width, height)

      vips! do |builder|
        builder.resize_to_limit(width, height)
          .apply(combine_options)
      end
    end

    ##
    # Resize the image to fit within the specified dimensions while retaining
    # the original aspect ratio. The image may be shorter or narrower than
    # specified in the smaller dimension but will not be larger than the specified values.
    #
    # === Parameters
    #
    # [width (Integer)] the width to scale the image to
    # [height (Integer)] the height to scale the image to
    # [combine_options (Hash)] additional Vips options to apply before resizing
    #
    # === Yields
    #
    # [Vips::Image] additional manipulations to perform
    #
    def resize_to_fit(width, height, combine_options: {})
      width, height = resolve_dimensions(width, height)

      vips! do |builder|
        builder.resize_to_fit(width, height)
          .apply(combine_options)
      end
    end

    ##
    # Resize the image to fit within the specified dimensions while retaining
    # the aspect ratio of the original image. If necessary, crop the image in the
    # larger dimension.
    #
    # === Parameters
    #
    # [width (Integer)] the width to scale the image to
    # [height (Integer)] the height to scale the image to
    # [combine_options (Hash)] additional vips options to apply before resizing
    #
    # === Yields
    #
    # [Vips::Image] additional manipulations to perform
    #
    def resize_to_fill(width, height, _gravity = nil, combine_options: {})
      width, height = resolve_dimensions(width, height)

      vips! do |builder|
        builder.resize_to_fill(width, height).apply(combine_options)
      end
    end

    ##
    # Resize the image to fit within the specified dimensions while retaining
    # the original aspect ratio. If necessary, will pad the remaining area
    # with the given color, which defaults to transparent (for gif and png,
    # white for jpeg).
    #
    # See https://libvips.github.io/libvips/API/current/libvips-conversion.html#VipsCompassDirection
    # for gravity options.
    #
    # === Parameters
    #
    # [width (Integer)] the width to scale the image to
    # [height (Integer)] the height to scale the image to
    # [background (List, nil)] the color of the background as a RGB, like [0, 255, 255], nil indicates transparent
    # [gravity (String)] how to position the image
    # [alpha (Boolean, nil)] pad the image with the alpha channel if supported
    # [combine_options (Hash)] additional vips options to apply before resizing
    #
    # === Yields
    #
    # [Vips::Image] additional manipulations to perform
    #
    def resize_and_pad(width, height, background=nil, gravity='centre', alpha=nil, combine_options: {})
      width, height = resolve_dimensions(width, height)

      vips! do |builder|
        builder.resize_and_pad(width, height, background: background, gravity: gravity, alpha: alpha)
          .apply(combine_options)
      end
    end

    ##
    # Returns the width of the image in pixels.
    #
    # === Returns
    #
    # [Integer] the image's width in pixels
    #
    def width
      vips_image.width
    end

    ##
    # Returns the height of the image in pixels.
    #
    # === Returns
    #
    # [Integer] the image's height in pixels
    #
    def height
      vips_image.height
    end

    # Process the image with vip, using the ImageProcessing gem. This
    # method will build a "convert" vips command and execute it on the
    # current image.
    #
    # === Gotcha
    #
    # This method assumes that the object responds to +current_path+.
    # Any class that this module is mixed into must have a +current_path+ method.
    # CarrierWave::Uploader does, so you won't need to worry about this in
    # most cases.
    #
    # === Yields
    #
    # [ImageProcessing::Builder] use it to define processing to be performed
    #
    # === Raises
    #
    # [CarrierWave::ProcessingError] if processing failed.
    def vips!
      builder = ImageProcessing::Vips.source(current_path)
      builder = yield(builder)

      result = builder.call
      result.close

      FileUtils.mv result.path, current_path

      if File.extname(result.path) != File.extname(current_path)
        move_to = current_path.chomp(File.extname(current_path)) + File.extname(result.path)
        file.content_type = ::MiniMime.lookup_by_filename(move_to).content_type
        file.move_to(move_to, permissions, directory_permissions)
      end
    rescue ::Vips::Error => e
      message = I18n.translate(:"errors.messages.vips_processing_error", :e => e)
      raise CarrierWave::ProcessingError, message
    end

    private

      def resolve_dimensions(*dimensions)
        dimensions.map do |value|
          next value unless value.instance_of?(Proc)
          value.arity >= 1 ? value.call(self) : value.call
        end
      end

      def vips_image
        ::Vips::Image.new_from_buffer(read, "")
      end

  end # Vips
end # CarrierWave
