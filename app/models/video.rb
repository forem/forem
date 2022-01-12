class Video
  extend CarrierWave::Mount
  extend CarrierWaveDirect::Mount

  mount_uploader :file, VideoUploader
end
