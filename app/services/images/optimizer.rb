module Images
  module Optimizer
    def self.call(img_src, **kwargs)
      if imgproxy_enabled?
        imgproxy(img_src, kwargs)
      else
        cloudinary(img_src, kwargs)
      end
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
      Imgproxy.config.endpoint ||= get_imgproxy_endpoint
      Imgproxy.url_for(img_src, options)
    end

    def self.imgproxy_enabled?
      Imgproxy.config.key.present? && Imgproxy.config.salt.present?
    end

    def self.get_imgproxy_endpoint
      if Rails.env.production?
        # Use /images with the same domain on Production as
        # our default configuration
        URL.url("images")
        # ie. https://forem.dev/images
      else
        # On other environments, rely on ApplicationConfig for a
        # more flexible configuration
        # ie. default imgproxy endpoint is localhost:8080
        ApplicationConfig["IMGPROXY_ENDPOINT"]
      end
    end
  end
end
