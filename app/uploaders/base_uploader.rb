class BaseUploader < CarrierWave::Uploader::Base
  include CarrierWave::BombShelter # limits size to 4096x4096
  include CarrierWave::MiniMagick # adds processing operations

  process :strip_exif

  def store_dir
    # eg. uploads/user/profile_image/1/e481b7ee.jpg
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  def extension_whitelist
    %w[jpg jpeg jpe gif png ico bmp dng]
  end

  def size_range
    1..25.megabytes
  end

  protected

  # strip EXIF (and GPS) data
  def strip_exif
    manipulate! do |image|
      image.strip
      image = yield(image) if block_given?
      image
    end
  end
end
