class CloudCoverUrl
  include CloudinaryHelper
  include ActionView::Helpers::AssetUrlHelper

  def initialize(url)
    @url = url
  end

  def call
    return if url.blank?
    return url if Rails.env.development? || Rails.env.test?

    if SiteConfig.main_image_crop == "max_square"
      max_square_config
    else
      base_config
    end
  end

  private

  def base_config
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

  def max_square_config
    width = 1000
    height = 1000
    quality = "auto"

    cl_image_path(url,
                  type: "fetch",
                  quality: quality,
                  flags: "progressive",
                  fetch_format: "auto",
                  transformation: [
                    { width: width, crop: "scale" },
                    { width: width, height: height, crop: "lfill" },
                  ],
                  sign_url: true)
  end

  attr_reader :url
end
