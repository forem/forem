module DataUpdateScripts
  class MoveMascotSettings
    SETTINGS = %w[
      footer_image_height
      footer_image_url
      footer_image_width
      image_description
      image_url
    ].freeze

    def run
      SETTINGS.each do |setting|
        if (value = SiteConfig.public_send("mascot_#{setting}"))
          Settings::Mascot.public_send("#{setting}=", value)
        end
      end
      Settings::Mascot.mascot_user_id = SiteConfig.mascot_user_id
    end
  end
end
