module Constants
  module SiteConfig
    IMAGE_PLACEHOLDER = "https://url/image.png".freeze
    SVG_PLACEHOLDER = "<svg ...></svg>".freeze

    DETAILS = {
      credit_prices_in_cents: {
        small: {
          description: "Price for small credit purchase (<10 credits).",
          placeholder: ""
        },
        medium: {
          description: "Price for medium credit purchase (10 - 99 credits).",
          placeholder: ""
        },
        large: {
          description: "Price for large credit purchase (100 - 999 credits).",
          placeholder: ""
        },
        xlarge: {
          description: "Price for extra large credit purchase (1000 credits or more).",
          placeholder: ""
        }
      },
      email_addresses: {
        description: "Email address",
        placeholder: ""
      },
      favicon_url: {
        description: "Used as the site favicon",
        placeholder: IMAGE_PLACEHOLDER
      },
      ga_tracking_id: {
        description: "Google Analytics Tracking ID, e.g. UA-71991000-1",
        placeholder: ""
      },
      health_check_token: {
        description: "Used to authenticate with your health check endpoints.",
        placeholder: "a secure token"
      },
      logo_png: {
        description: "Used as a fallback to the SVG. Recommended minimum of 512x512px for PWA support",
        placeholder: IMAGE_PLACEHOLDER
      },
      logo_svg: {
        description: "Used as the SVG logo of the community",
        placeholder: SVG_PLACEHOLDER
      },
      main_social_image: {
        description: "Used as the main image in social networks and OpenGraph. Recommended aspect ratio of 16:9 (600x337px,1200x675px)",
        placeholder: IMAGE_PLACEHOLDER
      },
      mailchimp_api_key: {
        description: "API key used to connect Mailchimp account. Found in Mailchimp backend",
        placeholder: ""
      },
      mailchimp_newsletter_id: {
        description: "Main Newsletter ID, also known as Audience ID",
        placeholder: ""
      },
      mailchimp_sustaining_members_id: {
        description: "Sustaining Members Newsletter ID",
        placeholder: ""
      },
      mailchimp_tag_moderators_id: {
        description: "Tag Moderators Newsletter ID",
        placeholder: ""
      },
      mailchimp_community_moderators_id: {
        description: "Community Moderators Newsletter ID",
        placeholder: ""
      },
      mascot_image_url: {
        description: "Used as the mascot image.",
        placeholder: ::Constants::SiteConfig::IMAGE_PLACEHOLDER
      },
      mascot_user_id: {
        description: "User ID of the Mascot account",
        placeholder: "1"
      },
      meta_keywords: {
        description: "",
        placeholder: "List of valid keywords: comma separated, letters only e.g. engineering, development"
      },
      onboarding_background_image: {
        description: "Background for onboarding splash page",
        placeholder: IMAGE_PLACEHOLDER
      },
      payment_pointer: {
        description: "Used for site-wide web monetization. " \
        "See: https://github.com/thepracticaldev/dev.to/pull/6345",
        placeholder: "$pay.somethinglikethis.co/value"
      },
      periodic_email_digest: {
        description: "Determines how often periodic email digests are sent",
        placeholder: 2
      },
      shop_url: {
        description: "Used as the shop url of the community",
        placeholder: "https://shop.url"
      },
      sidebar_tags: {
        description: "Determines which tags are shown on the homepage righthand sidebar",
        placeholder: "List of valid, comma-separated tags e.g. help,discuss,explainlikeimfive,meta"
      },
      sponsor_headline: {
        description: "Determines the heading text of the main sponsors sidebar above the list of sponsors.",
        placeholder: "Community Sponsors"
      },
      stripe_api_key: {
        description: "Secret Stripe key for receiving payments. " \
        "See: https://stripe.com/docs/keys",
        placeholder: "sk_live_...."
      },
      stripe_publishable_key: {
        description: "Public Stripe key for receiving payments. " \
        "See: https://stripe.com/docs/keys",
        placeholder: "pk_live_...."
      },
      suggested_tags: {
        description: "Determines which tags are suggested to new users during onboarding (comma
        separated, letters only)",
        placeholder: "List of valid tags: comma separated, letters only e.g. beginners,javascript,ruby,swift,kotlin"
      },
      suggested_users: {
        description: "Determines which users are suggested to follow to new users during onboarding (comma " \
        "separated, letters only). Please note that these users will be shown as a fallback if no " \
        "recently-active commenters or producers can be suggested",
        placeholder: "List of valid usernames: comma separated, letters only e.g. ben,jess,peter,maestromac,andy,liana"
      },
      prefer_manual_suggested_users: {
        description: "Always show suggested users as suggested people to follow even when " \
        "auto-suggestion is available"
      },
      twitter_hashtag: {
        description: "Used as the twitter hashtag of the community",
        placeholder: "#DEVCommunity"
      },
      video_encoder_key: {
        description: "Secret key used to allow AWS video encoding through the VideoStatesController",
        placeholder: ""
      }
      # Dynamic values ommitted: configurable_rate_limits and social_media_handles
    }.freeze
  end
end
