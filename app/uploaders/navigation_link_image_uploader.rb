class NavigationLinkImageUploader < BaseUploader
  MAX_FILE_SIZE = 5.megabytes
  EXTENSION_ALLOWLIST = %w[png jpg jpeg jpe].freeze
  IMAGE_TYPE_ALLOWLIST = %i[png jpg jpeg jpe].freeze
  CONTENT_TYPE_ALLOWLIST = %w[image/png image/jpg image/jpeg].freeze

  def store_dir
    "uploads/navigation_link_images/"
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
    "#{secure_token}.#{file.extension}" if original_filename.present?
  end

  protected

  def secure_token
    var = :"@#{mounted_as}_secure_token"
    model.instance_variable_get(var) || model.instance_variable_set(var, SecureRandom.uuid)
  end
end

