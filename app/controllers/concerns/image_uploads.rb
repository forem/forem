# Helpers included in ApplicationController for working with image files
module ImageUploads
  extend ActiveSupport::Concern

  MAX_FILENAME_LENGTH = 250

  def long_filename?(image)
    image&.original_filename && image.original_filename.length > MAX_FILENAME_LENGTH
  end

  def file?(image)
    image.respond_to?(:original_filename)
  end

  def filename_too_long_message
    I18n.t("concerns.image_uploads.too_long", max: MAX_FILENAME_LENGTH)
  end

  def is_not_file_message # rubocop:disable Naming/PredicateName
    I18n.t("concerns.image_uploads.is_not_file")
  end
end
