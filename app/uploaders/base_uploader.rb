class BaseUploader < CarrierWave::Uploader::Base
  include CarrierWave::BombShelter # limits size to 4096x4096

  EXTENSION_ALLOWLIST = %w[jpg jpeg jpe gif png ico bmp dng webp].freeze
  FRAME_MAX = 500
  FRAME_STRIP_MAX = 150
  DEFAULT_SVG_FONT_PATH = Rails.root.join("app/assets/fonts/NotoSans-Bold.ttf").to_s.freeze

  process :validate_frame_count
  process :strip_exif

  class << self
    def resize_to_limit(width, height)
      process resize_to_limit: [width, height]
    end

    def resize_to_fill(width, height, gravity = "Center")
      process resize_to_fill: [width, height, gravity]
    end
  end

  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  def extension_allowlist
    EXTENSION_ALLOWLIST
  end

  def size_range
    1..(25.megabytes)
  end

  # Only move cached files in-place when storing to local File storage.
  # Fog#store! uploads the cached file without unlinking it from disk, so
  # returning false when _storage is Fog ensures CarrierWave::Uploader::Store#store!
  # deletes the temporary cached file from local disk after uploading to S3.
  def move_to_store
    super && _storage == CarrierWave::Storage::File
  end

  # Avoid triggering a synchronous S3 HEAD request when checking `#blank?` / `#present?`
  # (e.g. inside ActiveModel::EachValidator#validate or view/controller presence checks).
  def blank?
    return true if file.nil?
    return file.path.blank? if file.is_a?(CarrierWave::Storage::Fog::File)

    file.blank?
  end

  # Resizes the image to fit within `width x height` while preserving aspect ratio
  # (never upscaling smaller images), powered in-process by `ForemNative`.
  def resize_to_limit(width, height, combine_options: nil) # rubocop:disable Lint/UnusedMethodArgument
    resolved_width, resolved_height = resolve_dimensions(width, height)
    encoded, fmt = ForemNative.image_resize_to_limit(
      File.binread(current_path),
      resolved_width,
      resolved_height,
      font_path: DEFAULT_SVG_FONT_PATH,
    )
    write_processed_bytes!(encoded, fmt)
  rescue ArgumentError
    raise CarrierWave::ProcessingError, I18n.t(:"errors.messages.processing_error")
  end

  # Resizes the image to cover `width x height` and crops according to `gravity`
  # (default `"Center"`), powered in-process by `ForemNative`.
  def resize_to_fill(width, height, gravity = "Center", combine_options: nil) # rubocop:disable Lint/UnusedMethodArgument
    resolved_width, resolved_height = resolve_dimensions(width, height)
    encoded, fmt = ForemNative.image_resize_to_fill(
      File.binread(current_path),
      resolved_width,
      resolved_height,
      gravity,
      font_path: DEFAULT_SVG_FONT_PATH,
    )
    write_processed_bytes!(encoded, fmt)
  rescue ArgumentError
    raise CarrierWave::ProcessingError, I18n.t(:"errors.messages.processing_error")
  end

  def width
    ForemNative.image_inspect(read)[:width]
  rescue ArgumentError
    raise CarrierWave::ProcessingError, I18n.t(:"errors.messages.processing_error")
  end

  def height
    ForemNative.image_inspect(read)[:height]
  rescue ArgumentError
    raise CarrierWave::ProcessingError, I18n.t(:"errors.messages.processing_error")
  end

  protected

  def strip_exif
    return if file.content_type&.include?("svg")
    return if frame_count > FRAME_STRIP_MAX

    ForemNative.strip_and_auto_orient_file!(current_path, frame_strip_max: FRAME_STRIP_MAX)
  rescue StandardError => e
    Rails.logger.error("Error stripping EXIF data: #{e}")
  end

  def validate_frame_count
    begin
      return unless frame_count(file.path) > FRAME_MAX
    rescue Timeout::Error
      raise CarrierWave::IntegrityError, I18n.t("uploaders.base_uploader.timeout")
    rescue ArgumentError
      raise CarrierWave::ProcessingError, I18n.t(:"errors.messages.processing_error")
    end

    raise CarrierWave::IntegrityError,
          I18n.t("uploaders.base_uploader.too_many_frames", frame_max: FRAME_MAX)
  end

  private

  def frame_count(target = nil)
    target_path = target.respond_to?(:path) ? target.path : (target || file.path)
    @frame_counts ||= {}
    return @frame_counts[target_path] if @frame_counts.key?(target_path)

    @frame_counts[target_path] = ForemNative.image_frame_count(target_path)
  end

  def resolve_dimensions(*dimensions)
    dimensions.map do |value|
      next value unless value.instance_of?(Proc)

      value.arity >= 1 ? value.call(self) : value.call
    end
  end

  def write_processed_bytes!(encoded, fmt)
    File.binwrite(current_path, encoded)
    return unless fmt == "png" && File.extname(current_path).casecmp(".svg").zero?

    move_to = "#{current_path.chomp(File.extname(current_path))}.png"
    file.content_type = "image/png"
    file.move_to(move_to, permissions, directory_permissions)
  end
end
