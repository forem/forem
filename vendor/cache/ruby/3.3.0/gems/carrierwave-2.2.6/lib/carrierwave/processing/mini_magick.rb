module CarrierWave

  ##
  # This module simplifies manipulation with MiniMagick by providing a set
  # of convenient helper methods. If you want to use them, you'll need to
  # require this file:
  #
  #     require 'carrierwave/processing/mini_magick'
  #
  # And then include it in your uploader:
  #
  #     class MyUploader < CarrierWave::Uploader::Base
  #       include CarrierWave::MiniMagick
  #     end
  #
  # You can now use the provided helpers:
  #
  #     class MyUploader < CarrierWave::Uploader::Base
  #       include CarrierWave::MiniMagick
  #
  #       process :resize_to_fit => [200, 200]
  #     end
  #
  # Or create your own helpers with the powerful minimagick! method, which
  # yields an ImageProcessing::Builder object. Check out the ImageProcessing
  # docs at http://github.com/janko-m/image_processing and the list of all
  # available ImageMagick options at
  # http://www.imagemagick.org/script/command-line-options.php for more info.
  #
  #     class MyUploader < CarrierWave::Uploader::Base
  #       include CarrierWave::MiniMagick
  #
  #       process :radial_blur => 10
  #
  #       def radial_blur(amount)
  #         minimagick! do |builder|
  #           builder.radial_blur(amount)
  #           builder = yield(builder) if block_given?
  #           builder
  #         end
  #       end
  #     end
  #
  # === Note
  #
  # The ImageProcessing gem uses MiniMagick, a mini replacement for RMagick
  # that uses ImageMagick command-line tools, to build a "convert" command that
  # performs the processing.
  #
  # You can find more information here:
  #
  # https://github.com/minimagick/minimagick/
  #
  #
  module MiniMagick
    extend ActiveSupport::Concern

    included do
      require "image_processing/mini_magick"
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

      def resize_to_fill(width, height, gravity='Center')
        process :resize_to_fill => [width, height, gravity]
      end

      def resize_and_pad(width, height, background=:transparent, gravity='Center')
        process :resize_and_pad => [width, height, background, gravity]
      end
    end

    ##
    # Changes the image encoding format to the given format
    #
    # See http://www.imagemagick.org/script/command-line-options.php#format
    #
    # === Parameters
    #
    # [format (#to_s)] an abreviation of the format
    #
    # === Yields
    #
    # [MiniMagick::Image] additional manipulations to perform
    #
    # === Examples
    #
    #     image.convert(:png)
    #
    def convert(format, page=nil, &block)
      minimagick!(block) do |builder|
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
    # [combine_options (Hash)] additional ImageMagick options to apply before resizing
    #
    # === Yields
    #
    # [MiniMagick::Image] additional manipulations to perform
    #
    def resize_to_limit(width, height, combine_options: {}, &block)
      width, height = resolve_dimensions(width, height)

      minimagick!(block) do |builder|
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
    # [combine_options (Hash)] additional ImageMagick options to apply before resizing
    #
    # === Yields
    #
    # [MiniMagick::Image] additional manipulations to perform
    #
    def resize_to_fit(width, height, combine_options: {}, &block)
      width, height = resolve_dimensions(width, height)

      minimagick!(block) do |builder|
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
    # [gravity (String)] the current gravity suggestion (default: 'Center'; options: 'NorthWest', 'North', 'NorthEast', 'West', 'Center', 'East', 'SouthWest', 'South', 'SouthEast')
    # [combine_options (Hash)] additional ImageMagick options to apply before resizing
    #
    # === Yields
    #
    # [MiniMagick::Image] additional manipulations to perform
    #
    def resize_to_fill(width, height, gravity = 'Center', combine_options: {}, &block)
      width, height = resolve_dimensions(width, height)

      minimagick!(block) do |builder|
        builder.resize_to_fill(width, height, gravity: gravity)
          .apply(combine_options)
      end
    end

    ##
    # Resize the image to fit within the specified dimensions while retaining
    # the original aspect ratio. If necessary, will pad the remaining area
    # with the given color, which defaults to transparent (for gif and png,
    # white for jpeg).
    #
    # See http://www.imagemagick.org/script/command-line-options.php#gravity
    # for gravity options.
    #
    # === Parameters
    #
    # [width (Integer)] the width to scale the image to
    # [height (Integer)] the height to scale the image to
    # [background (String, :transparent)] the color of the background as a hexcode, like "#ff45de"
    # [gravity (String)] how to position the image
    # [combine_options (Hash)] additional ImageMagick options to apply before resizing
    #
    # === Yields
    #
    # [MiniMagick::Image] additional manipulations to perform
    #
    def resize_and_pad(width, height, background=:transparent, gravity='Center', combine_options: {}, &block)
      width, height = resolve_dimensions(width, height)

      minimagick!(block) do |builder|
        builder.resize_and_pad(width, height, background: background, gravity: gravity)
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
      mini_magick_image[:width]
    end

    ##
    # Returns the height of the image in pixels.
    #
    # === Returns
    #
    # [Integer] the image's height in pixels
    #
    def height
      mini_magick_image[:height]
    end

    ##
    # Manipulate the image with MiniMagick. This method will load up an image
    # and then pass each of its frames to the supplied block. It will then
    # save the image to disk.
    #
    # NOTE: This method exists mostly for backwards compatibility, you should
    # probably use #minimagick!.
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
    # [MiniMagick::Image] manipulations to perform
    #
    # === Raises
    #
    # [CarrierWave::ProcessingError] if manipulation failed.
    #
    def manipulate!
      cache_stored_file! if !cached?
      image = ::MiniMagick::Image.open(current_path)

      image = yield(image)
      FileUtils.mv image.path, current_path

      image.run_command("identify", current_path)
    rescue ::MiniMagick::Error, ::MiniMagick::Invalid => e
      message = I18n.translate(:"errors.messages.mini_magick_processing_error", :e => e)
      raise CarrierWave::ProcessingError, message
    ensure
      image.destroy! if image
    end

    # Process the image with MiniMagick, using the ImageProcessing gem. This
    # method will build a "convert" ImageMagick command and execute it on the
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
    def minimagick!(block = nil)
      builder = ImageProcessing::MiniMagick.source(current_path)
      builder = yield(builder)

      result = builder.call
      result.close

      # backwards compatibility (we want to eventually move away from MiniMagick::Image)
      if block
        image  = ::MiniMagick::Image.new(result.path, result)
        image  = block.call(image)
        result = image.instance_variable_get(:@tempfile)
      end

      FileUtils.mv result.path, current_path

      if File.extname(result.path) != File.extname(current_path)
        move_to = current_path.chomp(File.extname(current_path)) + File.extname(result.path)
        file.content_type = ::MiniMime.lookup_by_filename(move_to).content_type
        file.move_to(move_to, permissions, directory_permissions)
      end
    rescue ::MiniMagick::Error, ::MiniMagick::Invalid => e
      message = I18n.translate(:"errors.messages.mini_magick_processing_error", :e => e)
      raise CarrierWave::ProcessingError, message
    end

    private

      def resolve_dimensions(*dimensions)
        dimensions.map do |value|
          next value unless value.instance_of?(Proc)
          value.arity >= 1 ? value.call(self) : value.call
        end
      end

      def mini_magick_image
        ::MiniMagick::Image.read(read)
      end

  end # MiniMagick
end # CarrierWave
