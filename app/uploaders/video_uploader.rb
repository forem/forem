class VideoUploader < CarrierWave::Uploader::Base
  include CarrierWaveDirect::Uploader

  # Since Video is not an AR model, we need to include modules here
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  def will_include_content_type
    true
  end

  default_content_type  "video/mpeg"
  allowed_content_types %w[video/mpeg video/mp4 video/ogg]

  def content_type_allowlist
    %w[video/mpeg video/mp4 video/ogg]
  end

  # Override the directory where uploaded files will be stored.
  # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/"
  end
end
