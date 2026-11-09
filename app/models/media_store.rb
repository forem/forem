class MediaStore < ApplicationRecord
  # media_type enum
  enum :media_type, { image: 0, video: 1, audio: 2 }

  before_validation :set_output_url_if_needed

  validates :original_url, :output_url, presence: true

  private

  # Uploads original_url via ArticleImageUploader and assigns output_url before
  # validation when output_url is not yet populated.
  def set_output_url_if_needed
    return if output_url.present? || original_url.blank?

    uploader = ArticleImageUploader.new
    self.output_url = uploader.upload_from_url(original_url)
  end
end
