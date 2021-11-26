class LogoUploader < BaseUploader
  process :resize_image
  EXTENSION_ALLOWLIST = %w[svg jpg jpeg jpe png].freeze

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
    # TODO: decide with @nickytonline on a size range that
    # matches the frotend validation.
    1..(3.megabytes)
  end

  def resize_image
    # Question: this alters the origiinal file, we are able
    # to make a copy if we think thats a better approach
    image = MiniMagick::Image.new(file.path)

    # TODO: update this to calculate the resize dimensions
    resize_dimensions = "512x512"
    image.resize resize_dimensions
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
