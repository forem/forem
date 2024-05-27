class MediaStore < ApplicationRecord
  # media_type enum
  enum media_type: { image: 0, video: 1, audio: 2 }

  before_validation :set_output_url_if_needed

  private

  def set_output_url_if_needed
    return if output_url.present?

    uploader = ArticleImageUploader.new
    self.output_url = uploader.upload_from_url(original_url)
  end
end
