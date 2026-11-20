require "carrierwave/test/matchers"

module ForemNativeCarrierWaveImageLoader
  ImageMetadata = Struct.new(:width, :height, :format, keyword_init: true)

  def load_image(filename)
    info = ForemNative.image_inspect_file(filename)
    ImageMetadata.new(width: info[:width], height: info[:height], format: info[:format])
  end
end

CarrierWave::Test::Matchers::ImageLoader.singleton_class.prepend(ForemNativeCarrierWaveImageLoader)
