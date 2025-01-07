module Images
  module Optimizer
    def self.call(img_src, **kwargs)
      return img_src if img_src.blank? || img_src.starts_with?("/")

      if imgproxy_enabled?
        imgproxy(img_src, **kwargs)
      elsif cloudinary_enabled? && !cloudflare_contextually_preferred?(img_src)
        cloudinary(img_src, **kwargs)
      elsif cloudflare_enabled?
        cloudflare(img_src, **kwargs)
      else
        img_src
      end
    end

    # Each service has different ways of describing image cropping.
    # for the ideal croping we want.
    # Cloudinary uses "fill" and "limit"
    # Cloudflare uses "cover" and "scale-down" respectively
    # imgproxy uses "fill" and "fit" respectively

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

    CLOUDFLARE_DIRECTORY = (ApplicationConfig["CLOUDFLARE_IMAGES_DIRECTORY"] || "cdn-cgi").freeze

    def self.cloudflare(img_src, **kwargs)
      template = Addressable::Template.new("https://{domain}/{directory}/image/{options*}/{src}")
      fit = kwargs[:crop] == "crop" ? "cover" : "scale-down"
      template.expand(
        domain: ApplicationConfig["CLOUDFLARE_IMAGES_DOMAIN"],
        directory: CLOUDFLARE_DIRECTORY,
        options: {
          width: kwargs[:width],
          height: kwargs[:height],
          fit: fit,
          gravity: "auto",
          format: "auto"
        },
        src: extract_suffix_url(img_src),
      ).to_s
    end

    def self.cloudinary(img_src, **kwargs)
      options = DEFAULT_CL_OPTIONS.merge(kwargs).compact_blank
      imagga = kwargs[:crop] == "crop" && ApplicationConfig["CROP_WITH_IMAGGA_SCALE"].present? && !kwargs[:never_imagga]
      options[:crop] = if imagga
                         "imagga_scale" # Legacy setting if admin imagga_scale set
                       elsif kwargs[:crop] == "crop"
                         "fill"
                       else
                         "limit"
                       end
      if img_src&.include?(".gif")
        options[:quality] = 66
      end

      ActionController::Base.helpers.cl_image_path(img_src, options)
    end

    DEFAULT_IMGPROXY_OPTIONS = {
      height: nil,
      width: nil,
      max_bytes: 500_000, # Keep everything under half of one MB.
      auto_rotate: true,
      gravity: "sm",
      resizing_type: "fit"
    }.freeze

    def self.imgproxy(img_src, **kwargs)
      translated_options = translate_cloudinary_options(kwargs)
      options = DEFAULT_IMGPROXY_OPTIONS.merge(translated_options).compact_blank
      Imgproxy.config.endpoint ||= get_imgproxy_endpoint
      Imgproxy.url_for(img_src, options)
    end

    def self.translate_cloudinary_options(options)
      options[:resizing_type] = if options[:crop] == "crop"
                                  "fill"
                                else
                                  "fit"
                                end

      options[:crop] = nil
      options[:fetch_format] = nil
      options[:never_imagga] = nil
      options
    end

    def self.imgproxy_enabled?
      Imgproxy.config.key.present? && Imgproxy.config.salt.present?
    end

    def self.cloudinary_enabled?
      config = Cloudinary.config

      config.cloud_name.present? && config.api_key.present? && config.api_secret.present?
    end

    def self.cloudflare_enabled?
      ApplicationConfig["CLOUDFLARE_IMAGES_DOMAIN"].present?
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
        ApplicationConfig["IMGPROXY_ENDPOINT"] || "http://localhost:8080"
      end
    end

    def self.extract_suffix_url(full_url)
      return full_url unless full_url&.starts_with?(cloudflare_prefix)

      uri = URI.parse(full_url)
      match = uri.path.match(%r{https?.+})
      CGI.unescape(match[0]) if match
    end

    # This is a feature-flagged Cloudflare preference for hosted images only — works specifically with S3-hosted image sources.
    def self.cloudflare_contextually_preferred?(img_src)
      return false unless cloudflare_enabled?
      return false unless FeatureFlag.enabled?(:cloudflare_preferred_for_hosted_images)

      img_src&.start_with?("https://#{ApplicationConfig['AWS_BUCKET_NAME']}.s3.amazonaws.com") ||
        (img_src&.start_with?(cloudflare_prefix) && !img_src&.end_with?("/"))
    end

    def self.cloudflare_prefix
      "https://#{ApplicationConfig['CLOUDFLARE_IMAGES_DOMAIN']}/#{CLOUDFLARE_DIRECTORY}/image"
    end
  end
end
