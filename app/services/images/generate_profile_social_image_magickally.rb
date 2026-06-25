module Images
  class GenerateProfileSocialImageMagickally
    MEDIUM_FONT_PATH = "app/assets/fonts/Roboto-Medium.ttf".freeze
    BOLD_FONT_PATH = "app/assets/fonts/Roboto-Bold.ttf".freeze
    TEMPLATE_PATH = "app/assets/images/social_template.png".freeze
    ROUNDED_MASK_PATH = "app/assets/images/rounded_mask.png".freeze

    def self.call(resource)
      new(resource).call
    end

    def initialize(resource)
      @resource = resource
    end

    def call
      return unless @resource.is_a?(User) || @resource.is_a?(Organization)

      read_files
      url = generate_magickally
      if @resource.is_a?(User)
        profile = @resource.profile || @resource.create_profile
        profile.update_column(:data, profile.data.merge("social_image" => url))
        Users::BustProfileDetailsCacheWorker.perform_async(@resource.id)
      else
        @resource.update_column(:social_image, url)
      end
    rescue OpenURI::HTTPError, Timeout::Error, Net::OpenTimeout, Net::ReadTimeout => e
      Rails.logger.warn("[GenerateProfileSocialImageMagickally] Image fetch failed: #{e.message}")
    rescue MiniMagick::Error => e
      if e.message.include?("status: 15")
        Rails.logger.warn("[GenerateProfileSocialImageMagickally] MiniMagick terminated by SIGTERM")
      else
        Honeybadger.notify(e)
      end
    rescue StandardError => e
      Rails.logger.error(e)
      Honeybadger.notify(e)
    end

    private

    def generate_magickally
      @background_image.resize "1200x627!"
      result = draw_stripe
      result = add_logo(result)
      result = add_text(result)
      result = add_profile_image(result)
      upload_result(result)
    end

    def draw_stripe
      color = if @resource.is_a?(User)
                @resource.setting&.brand_color1
              else
                @resource.bg_color_hex
              end
      color = color.presence || "#111212"
      color = "#111212" if color == "#000000" # pure black has minimagick side effects

      @background_image.combine_options do |c|
        c.fill color
        c.draw "rectangle 0,0 1200,30"
      end
    end

    def add_logo(result)
      if @logo_image
        @logo_image.combine_options do |c|
          c.stroke "white"
          c.strokewidth "4"
          c.fill "none"
          c.draw "rectangle 0,0 1200,1200"
        end
        @logo_image.resize "77x77"
        result = @background_image.composite(@logo_image) do |c|
          c.compose "Over"
          c.geometry "+1020+466"
        end
      end
      result
    end

    def add_text(result)
      name = @resource.name.to_s
      escaped_name = name.gsub('"', '\\"')
      name_font_size = calculate_name_font_size(name)

      result.combine_options do |c|
        c.gravity "West"
        c.pointsize name_font_size.to_s
        c.draw "text 320,-80 \"#{escaped_name}\""
        c.fill "black"
        c.font BOLD_FONT_PATH.to_s
      end

      secondary_text = if @resource.is_a?(User)
                         "@#{@resource.username}"
                       else
                         @resource.tag_line.to_s
                       end

      if secondary_text.present?
        escaped_secondary = secondary_text.gsub('"', '\\"')
        result.combine_options do |c|
          c.gravity "West"
          c.pointsize "36"
          c.draw "text 320,-20 \"#{escaped_secondary}\""
          c.fill "#525252"
          c.font MEDIUM_FONT_PATH.to_s
        end
      end

      description = if @resource.is_a?(User)
                      @resource.profile&.summary.to_s
                    else
                      @resource.summary.to_s
                    end

      if description.present?
        wrapped_desc = wrap_description(description)
        escaped_desc = wrapped_desc.gsub('"', '\\"')
        result.combine_options do |c|
          c.gravity "West"
          c.pointsize "28"
          c.draw "text 320,60 \"#{escaped_desc}\""
          c.fill "#525252"
          c.font MEDIUM_FONT_PATH.to_s
        end
      end

      result
    end

    def calculate_name_font_size(text)
      text_length = text.length
      if text_length < 18
        80
      elsif text_length < 30
        70
      elsif text_length < 45
        60
      else
        50
      end
    end

    def wrap_description(text)
      text = text.truncate(160)
      text.split("\n").map do |line|
        line.length > 55 ? line.gsub(/(.{1,55})(\s+|$)/, "\\1\n").strip : line
      end * "\n"
    end

    def add_profile_image(result)
      profile_image_size = "180x180"

      @profile_image.collapse!
      @profile_image.format("png")
      @profile_image.resize profile_image_size

      result = result.composite(@profile_image) do |c|
        c.compose "Over"
        c.gravity "West"
        c.geometry "+96+0"
      end

      @rounded_mask.resize profile_image_size

      result.composite(@rounded_mask) do |c|
        c.compose "Over"
        c.gravity "West"
        c.geometry "+96+0"
      end
    rescue Timeout::Error, StandardError => e
      Honeybadger.notify(e)
      result
    end

    def upload_result(result)
      tempfile = Tempfile.new(["output", ".png"])
      result.write tempfile.path
      image_uploader = ProfileSocialImageUploader.new.tap do |uploader|
        uploader.store!(tempfile)
      end
      tempfile.close
      tempfile.unlink
      image_uploader.url
    end

    def read_files
      subforem_id = Subforem.cached_default_id
      logo_url = Settings::General.logo_png(subforem_id: subforem_id)

      profile_image_url = if @resource.is_a?(User)
                            @resource.profile_image_90.to_s
                          else
                            @resource.profile_image.to_s
                          end
      profile_image_url = profile_image_url.start_with?("http") ? profile_image_url : Images::Profile::BACKUP_LINK

      @background_image = MiniMagick::Image.open(TEMPLATE_PATH)
      @logo_image = logo_url.present? ? MiniMagick::Image.open(logo_url) : nil
      @profile_image = MiniMagick::Image.open(profile_image_url)
      @rounded_mask = MiniMagick::Image.open(ROUNDED_MASK_PATH)
    end
  end
end
