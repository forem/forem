class LogoUploader < BaseUploader
  MAX_FILE_SIZE = 8.megabytes
  STORE_DIRECTORY = "uploads/logos/".freeze
  EXTENSION_ALLOWLIST = %w[png jpg jpeg jpe].freeze
  IMAGE_TYPE_ALLOWLIST = %i[png jpg jpeg jpe].freeze
  CONTENT_TYPE_ALLOWLIST = %w[image/png image/jpg image/jpeg].freeze
  ALLOWED_TYPES = (CONTENT_TYPE_ALLOWLIST + EXTENSION_ALLOWLIST.map { |extension| ".#{extension}" }).join(",")

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

  def size_range
    1..MAX_FILE_SIZE
  end

  def content_type_allowlist
    CONTENT_TYPE_ALLOWLIST
  end

  def filename
    # random_string in the filename to avoid caching issues
    "original_logo_#{random_string}.#{file.extension}"
  end

  version :resized_logo do
    process resize_to_limit: [nil, 80]
    def full_filename(_for_file = file)
      "resized_logo_#{random_string}.#{file.extension}"
    end
  end

  private

  def random_string
    SecureRandom.alphanumeric(20)
  end
end
