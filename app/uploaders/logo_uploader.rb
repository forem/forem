class LogoUploader < BaseUploader
  MAX_FILE_SIZE = 3 # Megabytes
  EXTENSION_ALLOWLIST = %w[svg png jpg jpeg jpe].freeze
  CONTENT_TYPE_ALLOWLIST = %w[image/svg+xml image/png image/jpg image/jpeg].freeze

  def store_dir
    "uploads/logos/"
  end

  def extension_allowlist
    EXTENSION_ALLOWLIST
  end

  def image_type_whitelist
    %i[svg jpg jpeg jpe png]
  end

  def size_range
    1..(MAX_FILE_SIZE.megabytes)
  end

  def content_type_allowlist
    CONTENT_TYPE_ALLOWLIST
  end

  def filename
    "original_logo.#{file.extension}" if original_filename
  end

  version :resized_web_logo, if: :not_svg? do
    process resize_to_limit: [nil, 40]
    def full_filename(_for_file = file)
      "resized_web_logo.#{file.extension}" if original_filename
    end
  end

  #  it will take less time to generate resized_mobile_logo a smaller, already processed image
  version :resized_mobile_logo, if: :not_svg?, from_version: :resized_web_logo do
    process resize_to_limit: [112, 40]
    def full_filename(_for_file = file)
      "resized_mobile_logo.#{file.extension}" if original_filename
    end
  end

  private

  def not_svg?(file)
    file.content_type.exclude?("svg")
  end
end
