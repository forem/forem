module Constants
  module Settings
    module Mascot
      DETAILS = {
        footer_image_url: {
          description: "Special cute mascot image used in the footer.",
          placeholder: ::Constants::SiteConfig::IMAGE_PLACEHOLDER
        },
        footer_image_width: {
          description: "The footer mascot width will resized to this value, defaults to 52",
          placeholder: ""
        },
        footer_image_height: {
          description: "The footer mascot height will be resized to this value, defaults to 120",
          placeholder: ""
        },
        image_description: {
          description: "Used as the alt text for the mascot image",
          placeholder: ""
        },
        image_url: {
          description: "Used as the mascot image.",
          placeholder: ::Constants::SiteConfig::IMAGE_PLACEHOLDER
        },
        mascot_user_id: {
          description: "User ID of the Mascot account",
          placeholder: "1"
        }
      }.freeze
    end
  end
end
