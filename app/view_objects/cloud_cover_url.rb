class CloudCoverUrl
  include CloudinaryHelper
  include ActionView::Helpers::AssetUrlHelper

  def initialize(url)
    @url = url
  end

  def call
    return if url.blank?
    return url if Rails.env.development? || Rails.env.test?

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
