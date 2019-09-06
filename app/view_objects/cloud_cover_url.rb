class CloudCoverUrl
  include CloudinaryHelper
  include ActionView::Helpers::AssetUrlHelper

  def initialize(url)
    @url = url
  end

  def call
    return if url.blank?
    return asset_path("triple-unicorn") if Rails.env.test?
    return url if Rails.env.development?

    width = 1000
    height = 420
    quality = "auto"

    cl_image_path(url,
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

  attr_reader :url
end
