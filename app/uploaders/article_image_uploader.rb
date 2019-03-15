class ArticleImageUploader < CarrierWave::Uploader::Base
  include CarrierWave::BombShelter
  # Adds resolution size limit to images of 4096x4096

  def store_dir
    "i/"
  end

  def filename
    "#{Array.new(20) { rand(36).to_s(36) }.join}.#{file.extension}" if original_filename.present?
  end

  def extension_whitelist
    %w[jpg jpeg jpe gif png ico bmp dng]
  end
end
