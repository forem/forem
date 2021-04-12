module Constants
  module SiteConfig
    IMAGE_PLACEHOLDER = "https://url/image.png".freeze
    SVG_PLACEHOLDER = "<svg ...></svg>".freeze

    DETAILS = {
      campaign_articles_require_approval: {
        description: "",
        placeholder: "Campaign stories show up on sidebar with approval?"
      },
      campaign_call_to_action: {
        description: "This text populates the call to action button on the campaign sidebar",
        placeholder: "Share your project"
      },
      campaign_featured_tags: {
        description: "Posts with which tags will be featured in the campaign sidebar (comma separated, letters only)",
        placeholder: "List of campaign tags: comma separated, letters only e.g. tagone,tagtwo"
      },
      campaign_hero_html_variant_name: {
        description: "Hero HtmlVariant name",
        placeholder: ""
      },
      campaign_sidebar_enabled: {
        description: "",
        placeholder: "Campaign sidebar enabled or not"
      },
      campaign_sidebar_image: {
        description: IMAGE_PLACEHOLDER,
        placeholder: "Used at the top of the campaign sidebar"
      },
      campaign_url: {
        description: "https://url.com/lander",
        placeholder: "URL campaign sidebar image will link to"
      },
      campaign_articles_expiry_time: {
        description: "Sets the expiry time for articles (in weeks) to be displayed in campaign sidebar",
        placeholder: ""
      },
      community_copyright_start_year: {
        description: "Used to mark the year this forem was started.",
        placeholder: Time.zone.today.year.to_s
      },
      community_description: {
        description: "Used in meta description tags etc.",
        placeholder: "A fabulous community of kind and welcoming people."
      },
      community_emoji: {
        description: "Used in the title tags across the site alongside the community name",
        placeholder: ""
      },
      community_member_label: {
        description: "Used to determine what a member will be called e.g developer, hobbyist etc.",
        placeholder: "user"
      },
      community_name: {
        description: "Used as the primary name for your Forem, e.g. DEV, DEV Community, The DEV Community, etc.",
        placeholder: "New Forem"
      },
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
      default_font: {
        description: "Determines the default Base Reading Font (registered users can change this in their UX settings)"
      },
      display_jobs_banner: {
        description: "Display a jobs banner that points users to the jobs page when they type 'job'" \
        "or 'jobs' in the search box",
        placeholder: ""
      },
      email_addresses: {
        description: "Email address",
        placeholder: ""
      },
      experience_low: {
        description: "The label for the bottom of the experience level range of a post",
        placeholder: "Total Newbies"
      },
      experience_high: {
        description: "The label for the top of the experience level range of a post",
        placeholder: "Senior Devs"
      },
      favicon_url: {
        description: "Used as the site favicon",
        placeholder: IMAGE_PLACEHOLDER
      },
      feed_strategy: {
        description: "Determines the main feed algorithm approach the app takes: basic or large_forem_experimental
        (which should only be used for 10k+ member communities)",
        placeholder: "basic"
      },
      feed_style: {
        description: "Determines which default feed the users sees (rich content, more minimal, etc.)",
        placeholder: "basic, rich, or compact"
      },
      primary_brand_color_hex: {
        description: "Determines background/border of buttons etc. Must be dark enough to contrast with white text.",
        placeholder: "#0a0a0a"
      },
      ga_tracking_id: {
        description: "Google Analytics Tracking ID, e.g. UA-71991000-1",
        placeholder: ""
      },
      health_check_token: {
        description: "Used to authenticate with your health check endpoints.",
        placeholder: "a secure token"
      },
      home_feed_minimum_score: {
        description: "Minimum score needed for a post to show up on the unauthenticated home page.",
        placeholder: "0"
      },
      jobs_url: {
        description: "URL of the website where open positions are posted",
        placeholder: "Jobs URL"
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
      mascot_footer_image_url: {
        description: "Special cute mascot image used in the footer.",
        placeholder: IMAGE_PLACEHOLDER
      },
      mascot_footer_image_width: {
        description: "The footer mascot width will resized to this value, defaults to 52",
        placeholder: ""
      },
      mascot_footer_image_height: {
        description: "The footer mascot height will be resized to this value, defaults to 120",
        placeholder: ""
      },
      mascot_image_description: {
        description: "Used as the alt text for the mascot image",
        placeholder: ""
      },
      mascot_image_url: {
        description: "Used as the mascot image.",
        placeholder: IMAGE_PLACEHOLDER
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
      secondary_logo_url: {
        description: "A place for an alternate logo, if you have one. Used throughout member onboarding and in some sign in forms.",
        placeholder: IMAGE_PLACEHOLDER
      },
      spam_trigger_terms: {
        description: "Individual (case insensitive) phrases that trigger spam alerts, comma separated.",
        placeholder: "used cars near you, pokemon go hack"
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
      staff_user_id: {
        description: "Account ID which acts as automated 'staff'— used principally for welcome thread.",
        placeholder: ""
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
      tag_feed_minimum_score: {
        description: "Minimum score needed for a post to show up on default tag page.",
        placeholder: "0"
      },
      tagline: {
        description: "Used in signup modal.",
        placeholder: "We're a place where coders share, stay up-to-date and grow their careers."
      },
      twitter_hashtag: {
        description: "Used as the twitter hashtag of the community",
        placeholder: "#DEVCommunity"
      },
      user_considered_new_days: {
        description: "The number of days a user is considered new. The default is 3 days, but you can disable this entirely by inputting 0.",
        placeholder: ::SiteConfig.user_considered_new_days
      },
      video_encoder_key: {
        description: "Secret key used to allow AWS video encoding through the VideoStatesController",
        placeholder: ""
      }
      # Dynamic values ommitted: configurable_rate_limits and social_media_handles
    }.freeze
  end
end
