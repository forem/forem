class LogoUploader < BaseUploader
  EXTENSION_ALLOWLIST = %w[svg jpg jpeg png].freeze

  def store_dir
    "uploads/logos/"
  end

  def extension_allowlist
    EXTENSION_ALLOWLIST
  end

  def image_type_whitelist
    %i[svg jpg jpeg png]
  end

  def size_range
    # TODO: decide with @nickytonline on a size range that
    # matches the frotend validation.
    1..(3.megabytes)
  end
  # def content_type_whitelist
  #   %w[image/svg+xml]
  # end

  # Process files as they are uploaded:
  # process scale: [200, 300]
  #
  # def scale(width, height)
  #   # do something
  # end

  # Override the filename of the uploaded files:
  # Avoid using model.id or version_name here, see uploader/store.rb for details.
  # def filename
  #   "something.jpg" if original_filename
  # end
end
