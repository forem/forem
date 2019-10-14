class BaseUploader < CarrierWave::Uploader::Base
  # adds resolution size limit to images of 4096x4096
  include CarrierWave::BombShelter

  def store_dir
    # eg. uploads/user/profile_image/1/e481b7ee.jpg
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  def extension_whitelist
    %w[jpg jpeg jpe gif png ico bmp dng]
  end
end
