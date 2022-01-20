# This class backs the CarrierWaveDirect uploader.
class Video
  # Since this is not an ActiveRecord, we need to explicitly include these.
  extend CarrierWave::Mount
  extend CarrierWaveDirect::Mount

  mount_uploader :file, VideoUploader
end
