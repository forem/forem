class SubforemImageUploader < BaseUploader
  MAX_FILE_SIZE = 8.megabytes
  STORE_DIRECTORY = "uploads/subforem_images/".freeze
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
    "#{image_type}_#{random_string}.#{file.extension}"
  end

  # Main square logo - used in navigation and branding
  version :main_logo do
    process resize_to_fill: [128, 128]
    def full_filename(_for_file = file)
      "main_logo_#{random_string}.#{file.extension}"
    end
  end

  # Nav bar logo - smaller version for navigation
  version :nav_logo do
    process resize_to_fill: [80, 80]
    def full_filename(_for_file = file)
      "nav_logo_#{random_string}.#{file.extension}"
    end
  end

  # Social card image - wider aspect ratio for social media
  version :social_card do
    process resize_to_fill: [1200, 630]
    def full_filename(_for_file = file)
      "social_card_#{random_string}.#{file.extension}"
    end
  end

  def set_image_type(type)
    @image_type = type
  end

  def url
    # Ensure we return a full URL for Settings validation
    full_url = super
    return full_url if full_url.start_with?("http")

    # For file storage, construct the full URL
    if Rails.env.test?
      "https://test.host#{full_url}"
    else
      # In production, this should be handled by the asset_host configuration
      full_url
    end
  end

  private

  def random_string
    SecureRandom.alphanumeric(20)
  end

  def image_type
    # This will be set when the uploader is instantiated
    @image_type ||= "general"
  end
end
