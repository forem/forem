module Images
  module Optimizer
    DEFAULT_CL_OPTIONS = {
      type: "fetch",
      height: nil,
      width: nil,
      crop: "limit",
      quality: "auto",
      flags: "progressive",
      fetch_format: "auto",
      sign_url: true
    }.freeze

    def self.call(img_src, **kwargs)
      options = DEFAULT_CL_OPTIONS.merge(kwargs).reject { |_, v| v.blank? }

      if img_src&.include?(".gif")
        options[:quality] = 66
      end

      ActionController::Base.helpers.cl_image_path(img_src, options)
    end
  end
end
