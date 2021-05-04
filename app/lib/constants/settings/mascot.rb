module Constants
  module Settings
    module Mascot
      DETAILS = {
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
