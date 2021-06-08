# Helpers included in ApplicationController for working with image files
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
end
