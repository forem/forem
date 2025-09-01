class BaseUploader < CarrierWave::Uploader::Base
  include CarrierWave::BombShelter  # limits size to 4096x4096
  include CarrierWave::MiniMagick   # adds processing operations

  EXTENSION_ALLOWLIST = %w[jpg jpeg jpe gif png ico bmp dng webp].freeze
  FRAME_MAX = 500
  FRAME_STRIP_MAX = 150

  process :validate_frame_count
  process :strip_exif

  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  def extension_allowlist
    EXTENSION_ALLOWLIST
  end

  def size_range
    1..(25.megabytes)
  end

  protected

  def strip_exif
    return if file.content_type.include?("svg")

    manipulate! do |image|
      image.auto_orient
      image.strip unless image.frames.count > FRAME_STRIP_MAX
      image = yield(image) if block_given?
      image
    end
  rescue StandardError => e
    Rails.logger.error("Error stripping EXIF data: #{e}")
  end

  def validate_frame_count
    begin
      return unless MiniMagick::Image.new(file.path).frames.count > FRAME_MAX
    rescue Timeout::Error
      raise CarrierWave::IntegrityError, I18n.t("uploaders.base_uploader.timeout")
    end

    raise CarrierWave::IntegrityError,
          I18n.t("uploaders.base_uploader.too_many_frames", frame_max: FRAME_MAX)
  end
end
