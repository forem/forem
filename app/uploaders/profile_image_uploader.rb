class ProfileImageUploader < CarrierWave::Uploader::Base
  include CarrierWave::BombShelter
  # Adds resolution size limit to images of 4096x4096

  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  def filename
    "#{secure_token}.#{file.extension}" if original_filename.present?
  end

  def extension_whitelist
    %w[jpg jpeg jpe gif png ico bmp dng]
  end

  def size_range
    1..2.megabytes
  end

  protected

  def secure_token
    var = :"@#{mounted_as}_secure_token"
    model.instance_variable_get(var) || model.instance_variable_set(var, SecureRandom.uuid)
  end
  # version :big_thumb do
  #  process :resize_to_limit => [280, 280]
  # end
  #
  # version :small_thumb do
  #  process :resize_to_limit => [100, 100]
  # end
end
