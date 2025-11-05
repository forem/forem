class NavigationLinkImageUploader < BaseUploader
  MAX_FILE_SIZE = 5.megabytes
  STORE_DIRECTORY = "uploads/navigation_link_images/".freeze
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
    return nil unless file.present?
    
    # random_string in the filename to avoid caching issues
    "#{model.id || 'temp'}_#{random_string}.#{file.extension}"
  end

  # Small icon version for sidebar navigation (24x24)
  version :icon do
    process resize_to_fill: [24, 24]
    def full_filename(_for_file = file)
      return nil unless file.present?
      
      "icon_#{model.id || 'temp'}_#{random_string}.#{file.extension}"
    end
  end

  # Medium icon version for other uses (48x48)
  version :medium do
    process resize_to_fill: [48, 48]
    def full_filename(_for_file = file)
      return nil unless file.present?
      
      "medium_#{model.id || 'temp'}_#{random_string}.#{file.extension}"
    end
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
    @random_string ||= SecureRandom.alphanumeric(20)
  end
end

