class CloudCoverUrl
  include CloudinaryHelper
  include ActionView::Helpers::AssetUrlHelper

  def initialize(url)
    @url = url
  end

  def call
    return if url.blank?
    return url if Rails.env.development?

    width = 1000
    height = 420
    quality = "auto"

    cl_image_path(url_without_prefix_nesting(url, width),
                  type: "fetch",
                  width: width,
                  height: height,
                  crop: "imagga_scale",
                  quality: quality,
                  flags: "progressive",
                  fetch_format: "auto",
                  sign_url: true)
  end

  private

  def url_without_prefix_nesting(url, width)
    return url if url.blank?
    return url unless url.start_with?("https://res.cloudinary.com/") && url.include?("w_#{width}/https://")

    url.split("w_#{width}/").last
  end

  attr_reader :url
end
