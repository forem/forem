# Inherits some functionality from Images::GenerateSocialImageMagickally

module Images
  class GenerateProfileSocialImageMagickally < Images::GenerateSocialImageMagickally
    def self.call(resource = nil)
      new(resource).call
    end

    def initialize(user)
      super
      @user = user
      @logo_url = Settings::General.logo_png
    end

    def call
      read_files
      url = generate_magickally(author_name: @user.name,
                                color: @user.setting.brand_color1)
      @user.profile.update_column(:social_image, url)
    rescue StandardError => e
      Rails.logger.error(e)
      Honeybadger.notify(e)
    end

    private

    def generate_magickally(author_name: nil, color: nil)
      result = draw_stripe(color)
      result = add_logo(result)
      result = add_text(result, author_name)
      result = add_profile_image(result)
      upload_result(result)
    end

    def add_text(result, author_name)
      result.combine_options do |c|
        escaped_name = author_name.gsub('"', '\\"')
        c.gravity "South"
        c.pointsize "32"
        c.draw "text 0,80 \"#{escaped_name}\"" # adjust coordinates as needed
        c.fill "black"
        c.font MEDIUM_FONT_PATH.to_s
      end
    end

    def add_profile_image(result)
      profile_image_size = "200x200"
      profile_image_location = "+0+0"
      # Add subtext and author image
      @author_image.resize profile_image_size
      result = result.composite(@author_image) do |c|
        c.compose "Over"
        c.gravity "Center"
        c.geometry profile_image_location
      end

      @rounded_mask.resize profile_image_size

      result.composite(@rounded_mask) do |c|
        c.compose "Over"
        c.gravity "Center"
        c.geometry profile_image_location
      end
    end

    def read_files
      # These are files we can open once for all the images we are generating within the loop.
      @background_image = MiniMagick::Image.open(TEMPLATE_PATH)
      @logo_image = MiniMagick::Image.open(@logo_url) if @logo_url.present?
      image = @user&.profile_image_url_for(length: 320).to_s
      author_image_url = image.start_with?("http") ? image : Images::Profile::BACKUP_LINK
      @author_image = MiniMagick::Image.open(author_image_url)
      @rounded_mask = MiniMagick::Image.open(ROUNDED_MASK_PATH)
    end
  end
end
