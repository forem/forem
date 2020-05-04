module ImageUploads
  extend ActiveSupport::Concern

  MAX_FILENAME_LENGTH = 250
  FILENAME_TOO_LONG_MESSAGE = "filename too long - the max is #{MAX_FILENAME_LENGTH} characters.".freeze
  IS_NOT_FILE_MESSAGE = "invalid file type. Please upload a valid image.".freeze

  def long_filename?(image)
    image&.original_filename && image.original_filename.length > MAX_FILENAME_LENGTH
  end

  def file?(image)
    image.respond_to?(:original_filename)
  end

  def log_image_data_to_datadog
    images = Array.wrap(
      params.dig("user", "profile_image") ||
      params.dig("podcast", "image") ||
      params.dig("organization", "profile_image") ||
      params["image"],
    )

    raise if images.empty?

    images.each do |image|
      tags = [
        "controller:#{params['controller']}",
        "action:#{params['action']}",
        "content_type:#{image.content_type}",
        "original_filename:#{image.original_filename}",
        "tempfile:#{image.tempfile}",
        "size:#{image.size}",
      ]

      DatadogStatsClient.increment("image_upload_error", tags: tags)
    end

    raise
  end
end
