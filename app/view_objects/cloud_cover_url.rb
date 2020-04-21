class CloudCoverUrl
  include CloudinaryHelper
  include ActionView::Helpers::AssetUrlHelper

  def initialize(url, options)
    @url = url
    @height = options[:height] || 420
    @width = options[:width] || 1000
  end

  def call
    return if url.blank?
    return url if Rails.env.development? || Rails.env.test?

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

  attr_reader :url, :height, :width
end
