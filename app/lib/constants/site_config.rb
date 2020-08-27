module Constants
  module SiteConfig
    DETAILS = {
      authentication_providers: {
        description: "How can users sign in?",
        placeholder: ""
      },
      campaign_articles_require_approval: {
        description: "",
        placeholder: "Campaign stories show up on sidebar with approval?"
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
        description: "https://image.url",
        placeholder: "Used at the top of the campaign sidebar"
      },
      campaign_url: {
        description: "https://url.com/lander",
        placeholder: "URL campaign sidebar image will link to"
      },
      community_action: {
        description: "Used to determine the action of community e.g coding, reading, training etc.",
        placeholder: "coding"
      },
      community_copyright_start_year: {
        description: "Used to mark the year this forem was started.",
        placeholder: Time.zone.today.year.to_s
      },
      community_description: {
        description: "Used in meta description tags etc.",
        placeholder: "A fabulous community of kind and welcoming people."
      },
      community_member_label: {
        description: "Used to determine what a member will be called e.g developer, hobbyist etc.",
        placeholder: "user"
      },
      community_name: {
        description: "Primary name... e.g. DEV",
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
      favicon_url: {
        description: "Used as the site favicon",
        placeholder: "https://image.url"
      },
      feed_style: {
        description: "Determines which default feed the users sees (rich content, more minimal, etc.)",
        placeholder: "basic, rich, or compact"
      },
      github_key: {
        description: "The \"Client ID\" portion of the GitHub Oauth Apps portal",
        placeholder: ""
      },
      github_secret: {
        description: "The \"Client Secret\" portion of the GitHub Oauth Apps portal",
        placeholder: ""
      },
      ga_view_id: {
        description: "Google Analytics Reporting API v4 - View ID",
        placeholder: ""
      },
      health_check_token: {
        description: "Used to authenticate with your health check endpoints.",
        placeholder: "a secure token"
      },
      jobs_url: {
        description: "URL of the website where open positions are posted",
        placeholder: "Jobs URL"
      },
      left_navbar_svg_icon: {
        description: "The SVG icon used to expand the left navbar navigation menu. Should be a max of 24x24px.",
        placeholder: "<svg ...></svg>"
      },
      logo_png: {
        description: "Minimum 1024px, used for PWA etc.",
        placeholder: "https://image.url/image.png"
      },
      logo_svg: {
        description: "Used as the SVG logo of the community",
        placeholder: "<svg ...></svg>"
      },
      main_social_image: {
        description: "Used as the main image in social networks and OpenGraph",
        placeholder: "https://image.url"
      },
      mailchimp_newsletter_id: {
        description: "Main Newsletter ID",
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
        placeholder: "https://image.url"
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
        placeholder: "https://image.url"
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
        placeholder: "https://image.url"
      },
      onboarding_logo_image: {
        description: "Main onboarding display logo image",
        placeholder: "https://image.url"
      },
      onboarding_taskcard_image: {
        description: "Used as the onboarding task-card image",
        placeholder: "https://image.url"
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
      right_navbar_svg_icon: {
        description: "The SVG icon used to expand the right navbar navigation menu. Should be a max of 24x24px.",
        placeholder: "<svg ...></svg>"
      },
      secondary_logo_url: {
        description: "Used as the secondary logo",
        placeholder: "https://image.url"
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
        description: "Determines which users are suggested to follow to new users during onboarding (comma" \
        "separated, letters only). Please note that these users will be shown as a fallback if no" \
        "recently-active commenters or producers can be suggested",
        placeholder: "List of valid usernames: comma separated, letters only e.g. ben,jess,peter,maestromac,andy,liana"
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
      }
      # Dynamic values ommitted: configurable_rate_limits and social_media_handles
    }.freeze
  end
end
