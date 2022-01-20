class VideoUploader < CarrierWave::Uploader::Base
  include CarrierWaveDirect::Uploader

  # Since Video is not an ActiveRecord, we need to explicitly include these.
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  # The default S3 content-type is "binary/octet-stream". Since we want to
  # stream videos we need to set this to a proper media type.
  # See: https://github.com/dwilkie/carrierwave_direct#content-type--mime
  def will_include_content_type
    true
  end

  default_content_type  "video/mpeg"
  allowed_content_types %w[video/mpeg video/mp4 video/ogg]

  # Override the directory where uploaded files will be stored.
  # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
    "video_uploads"
  end
end
