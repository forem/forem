module ImageResizer
  def self.call(img_src, height:, width:, crop:, quality:, flags:)
    options =  {
      type: "fetch",
      height: height,
      width: width,
      sign_url: true,
      crop: crop || "limit",
      quality: quality || "auto",
      fetch_format: "auto",
      flags: flags || "progressive"
    }.reject { |_, v| v.blank? }

    ActionController::Base.helpers.cl_image_path(img_src, options)
  end
end
