module Images
  module Optimizer
    def self.call(img_src, service: :cloudinary, **kwargs)
      return cloudinary(img_src, kwargs) unless imgproxy_enabled?

      public_send(service, img_src, kwargs)
    end

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

    def self.cloudinary(img_src, **kwargs)
      options = DEFAULT_CL_OPTIONS.merge(kwargs).reject { |_, v| v.blank? }

      if img_src&.include?(".gif")
        options[:quality] = 66
      end

      ActionController::Base.helpers.cl_image_path(img_src, options)
    end

    DEFAULT_IMGPROXY_OPTIONS = {
      height: nil,
      width: nil,
      resizing_type: nil
    }.freeze

    def self.imgproxy(img_src, **kwargs)
      options = DEFAULT_IMGPROXY_OPTIONS.merge(kwargs).reject { |_, v| v.blank? }

      Imgproxy.url_for(img_src, options)
    end

    def self.imgproxy_enabled?
      Imgproxy.config.key.present? && Imgproxy.config.endpoint.present?
    end
  end
end
