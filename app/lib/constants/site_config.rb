module Constants
  module SiteConfig
    IMAGE_PLACEHOLDER = "https://url/image.png".freeze
    SVG_PLACEHOLDER = "<svg ...></svg>".freeze

    DETAILS = {
      require_captcha_for_email_password_registration: {
        description: "People will be required to fill out a captcha when
          they're creating a new account in your community",
        placeholder: ""
      },
      allowed_registration_email_domains: {
        description: "Restrict registration to only certain emails? (comma-separated list)",
        placeholder: "dev.to, forem.com, codenewbie.org"
      },
      authentication_providers: {
        description: "How can users sign in?",
        placeholder: ""
      },
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
        placeholder: "List of campaign tags: comma separated, letters only e.g. shecoded,theycoded"
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
      display_email_domain_allow_list_publicly: {
        description: "Do you want to display the list of allowed domains, or keep it private?"
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
      facebook_key: {
        description:
          "The \"App ID\" portion of the Basic Settings section of the App page on the Facebook Developer Portal",
        placeholder: ""
      },
      facebook_secret: {
        description:
          "The \"App Secret\" portion of the Basic Settings section of the App page on the Facebook Developer Portal",
        placeholder: ""
      },
      apple_client_id: {
        description:
          "The \"App Bundle\" code for the Authentication Service configured in the Apple Developer Portal",
        placeholder: "com.example.app"
      },
      apple_team_id: {
        description:
          "The \"Team ID\" of your Apple Developer Account",
        placeholder: ""
      },
      apple_key_id: {
        description:
          "The \"Key ID\" from the Authentication Service configured in the Apple Developer Portal",
        placeholder: ""
      },
      apple_pem: {
        description:
          "The \"PEM\" key from the Authentication Service configured in the Apple Developer Portal",
        placeholder: "-----BEGIN PRIVATE KEY-----\nMIGTAQrux...QPe8Yb\n-----END PRIVATE KEY-----\\n"
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
      github_key: {
        description: "The \"Client ID\" portion of the GitHub Oauth Apps portal",
        placeholder: ""
      },
      github_secret: {
        description: "The \"Client Secret\" portion of the GitHub Oauth Apps portal",
        placeholder: ""
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
      invite_only_mode: {
        description: "Only users invited by email can join this community.",
        placeholder: ""
      },
      jobs_url: {
        description: "URL of the website where open positions are posted",
        placeholder: "Jobs URL"
      },
      left_navbar_svg_icon: {
        description: "The SVG icon used to expand the left navbar navigation menu. Should be a max of 24x24px.",
        placeholder: SVG_PLACEHOLDER
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
      onboarding_logo_image: {
        description: "Main onboarding display logo image",
        placeholder: IMAGE_PLACEHOLDER
      },
      onboarding_taskcard_image: {
        description: "Used as the onboarding task-card image",
        placeholder: IMAGE_PLACEHOLDER
      },
      payment_pointer: {
        description: "Used for site-wide web monetization. " \
        "See: https://github.com/thepracticaldev/dev.to/pull/6345",
        placeholder: "$pay.somethinglikethis.co/value"
      },
      periodic_email_digest_max: {
        description: "Determines the maximum for the periodic email digest",
        placeholder: 0
      },
      periodic_email_digest_min: {
        description: "Determines the mininum for the periodic email digest",
        placeholder: 2
      },
      recaptcha_site_key: {
        description: "Add the site key for Google reCAPTCHA, which is used for reporting abuse",
        placeholder: "What is the Google reCAPTCHA site key?"
      },
      recaptcha_secret_key: {
        description: "Add the secret key for Google reCAPTCHA, which is used for reporting abuse",
        placeholder: "What is the Google reCAPTCHA secret key?"
      },
      right_navbar_svg_icon: {
        description: "The SVG icon used to expand the right navbar navigation menu. Should be a max of 24x24px.",
        placeholder: SVG_PLACEHOLDER
      },
      secondary_logo_url: {
        description: "Used as the secondary logo",
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
        placeholder: "List of valid tags: comma separated, letters only e.g. help,discuss,explainlikeimfive,meta"
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
      twitter_key: {
        description: "The \"API key\" portion of consumer keys in the Twitter developer portal.",
        placeholder: ""
      },
      twitter_secret: {
        description: "The \"API secret key\" portion of consumer keys in the Twitter developer portal.",
        placeholder: ""
      },
      video_encoder_key: {
        description: "Secret key used to allow AWS video encoding through the VideoStatesController",
        placeholder: ""
      }
      # Dynamic values ommitted: configurable_rate_limits and social_media_handles
    }.freeze
  end
end
