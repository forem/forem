class LogoSvgUploader < BaseUploader
  # This Uploader is being used by a Data Update Script
  # lib/data_update_scripts/20211208074428_migrate_logo_svg_data.rb
  # to convert logo_svg contents to a png file.

  STORE_DIRECTORY = "uploads/logos/".freeze
  EXTENSION_ALLOWLIST = %w[svg png].freeze
  IMAGE_TYPE_ALLOWLIST = %i[svg png].freeze
  CONTENT_TYPE_ALLOWLIST = %w[image/svg+xml image/png].freeze

  process :convert_to_png

  def store_dir
    STORE_DIRECTORY
  end

  def extension_allowlist
    EXTENSION_ALLOWLIST
  end

  def image_type_whitelist
    # this is needed by CarrierWave::BombShelter
    IMAGE_TYPE_ALLOWLIST
  end

  def content_type_allowlist
    CONTENT_TYPE_ALLOWLIST
  end

  def filename
    # random_string in the filename to avoid caching issues
    "original_logo_#{random_string}.png"
  end

  def convert_to_png
    png_bytes = ForemNative.image_convert_to_png(
      File.binread(file.path),
      font_path: DEFAULT_SVG_FONT_PATH,
      reject_blank: true,
    )
    temp_png_file = Tempfile.new(["output", ".png"])

    begin
      temp_png_file.binmode
      temp_png_file.write(png_bytes)
      temp_png_file.flush

      file.instance_variable_set(:@file, temp_png_file)
      file.instance_variable_set(:@content_type, "image/png")
    ensure
      temp_png_file.close
    end
  rescue ArgumentError
    raise CarrierWave::ProcessingError, I18n.t(:"errors.messages.processing_error")
  end

  version :resized_logo do
    process resize_to_limit: [nil, 80]
    def full_filename(_for_file = file)
      "resized_logo_#{random_string}.png"
    end
  end

  private

  def random_string
    SecureRandom.alphanumeric(20)
  end
end
