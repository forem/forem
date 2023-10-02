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
      read_files(320)
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
      result = add_profile_image(result, "200x200", "+0+0", "Center")
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
  end
end
