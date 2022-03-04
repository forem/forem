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
    temp_png_file = Tempfile.new ["output", ".png"]

    begin
      MiniMagick::Tool::Convert.new do |convert|
        convert.background("none")
        convert << file.path
        convert << temp_png_file.path
      end

      # https://github.com/minimagick/minimagick/issues/332
      file.instance_variable_set(:@file, temp_png_file)
      file.instance_variable_set(:@content_type, "image/png")
    ensure
      temp_png_file.close
    end
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
