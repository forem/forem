module Constants
  module Settings
    module UserExperience
      DETAILS = {
        default_font: {
          description: "Determines the default reading font (registered users can change this in their UX settings)"
        },
        default_locale: {
          description: "Determines the default language and lozalization for the Forem (currently in experimental beta)"
        },
        feed_strategy: {
          description: "Determines the main feed algorithm approach the app takes: basic or large_forem_experimental " \
                       "(which should only be used for 10k+ member communities)",
          placeholder: "basic"
        },
        feed_style: {
          description: "Determines which default feed the users sees (rich content, more minimal, etc.)",
          placeholder: "basic, rich, or compact"
        },
        home_feed_minimum_score: {
          description: "Minimum score needed for a post to show up on the unauthenticated home page.",
          placeholder: "0"
        },
        primary_brand_color_hex: {
          description: "Determines background/border of buttons etc. Must be dark enough to contrast with white text.",
          placeholder: "#0a0a0a"
        },
        tag_feed_minimum_score: {
          description: "Minimum score needed for a post to show up on default tag page.",
          placeholder: "0"
        }
      }.freeze
    end
  end
end
