class BaseUploader < CarrierWave::Uploader::Base
  include CarrierWave::BombShelter # limits size to 4096x4096
  include CarrierWave::MiniMagick # adds processing operations

  process :strip_exif

  def store_dir
    # eg. uploads/user/profile_image/1/e481b7ee.jpg
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  # Extensions that are allowed to be uploaded
  def extension_whitelist
    %w[bmp gif ico jpe jpeg jpg png webp]
  end

  # File types that are allowed through by CarrierWave::BombShelter
  # CarrierWave::BombShelter by default only supports jpeg, png and gifs
  # see <https://github.com/DarthSim/carrierwave-bombshelter/blob/489e292992b2a3b3c76cda5ac51726ae8f1c7fe6/lib/carrierwave/bombshelter.rb#L34>
  # and <https://github.com/DarthSim/carrierwave-bombshelter#usage>.
  # Anyhow, it's possible to override the list of supported types within those
  # supported by FastImage (the gem CarrierWave::BombShelter uses to detect types)
  # see <https://github.com/sdsykes/fastimage/blob/099c5e42332081292a2420266401a4ad48244ba4/lib/fastimage.rb#L519>
  def image_type_whitelist
    %i[bmp cur gif ico jpeg png webp]
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
