class CloudCoverUrl
  include ActionView::Helpers::AssetUrlHelper

  def initialize(url, subforem_id = nil)
    @subforem_id = subforem_id || RequestStore.store[:subforem_id]
    @url = url
  end

  def call
    return if url.blank?
    return url if Rails.env.development?

    width = 1000
    height = Settings::UserExperience.cover_image_height(subforem_id: @subforem_id)
    crop = Settings::UserExperience.cover_image_fit(subforem_id: @subforem_id)

    # Hardcode for YouTube thumbnails
    if (url&.include?("ytimg.com"))
      height = 500
      crop = "crop"
    end

    img_src = url_without_prefix_nesting(url, width)

    Images::Optimizer.call(img_src, width: width, height: height, crop: crop)
  end

  private

  def url_without_prefix_nesting(url, width)
    return url if url.blank?
    return url unless url.start_with?("https://res.cloudinary.com/") && url.include?("w_#{width}/https://")

    url.split("w_#{width}/").last
  end

  attr_reader :url, :height
end
