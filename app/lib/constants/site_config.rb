module Constants
  module SiteConfig
    DETAILS = {
      authentication_providers: {
        description: "How can users sign in?",
        placeholder: ""
      },
      campaign_hero_html_variant_name: {
        description: "Hero HtmlVariant name",
        placeholder: ""
      },
      campaign_articles_require_approval: {
        description: "",
        placeholder: "Campaign stories show up on sidebar with approval?"
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
      campaign_featured_tags: {
        description: "Posts with which tags will be featured in the campaign sidebar (comma separated, letters only)",
        placeholder: "List of campaign tags: comma separated, letters only e.g. shecoded,theycoded"
      },
      community_description: {
        description: "Used in meta description tags etc.",
        placeholder: "A fabulous community of kind and welcoming people."
      },
      community_member_label: {
        description: "Used to determine what a member will be called e.g developer, hobbyist etc.",
        placeholder: "user"
      },
      community_action: {
        description: "Used to determine the action of community e.g coding, reading, training etc.",
        placeholder: ""
      },
      tagline: {
        description: "Used in signup modal.",
        placeholder: "We're a place where coders share, stay up-to-date and grow their careers."
      },
      email_addresses: {
        description: "Email address",
        placeholder: ""
      },
      periodic_email_digest_max: {
        description: "Determines the maximum for the periodic email digest",
        placeholder: 0
      },
      periodic_email_digest_min: {
        description: "Determines the mininum for the periodic email digest",
        placeholder: 2
      },
      jobs_url: {
        description: "URL of the website where open positions are posted",
        placeholder: "Jobs URL"
      },
      display_jobs_banner: {
        description: "Display a jobs banner that points users to the jobs page when they type 'job'" \
        "or 'jobs' in the search box",
        placeholder: ""
      },
      ga_view_id: {
        description: "Google Analytics Reporting API v4 - View ID",
        placeholder: ""
      },
      ga_fetch_rate: {
        description: "Determines how often the site updates its Google Analytics stats",
        placeholder: 1
      },
      main_social_image: {
        description: "Used as the main image in social networks and OpenGraph",
        placeholder: "https://image.url"
      },
      favicon_url: {
        description: "Used as the site favicon",
        placeholder: "https://image.url"
      },
      logo_png: {
        description: "Minimum 1024px, used for PWA etc.",
        placeholder: "https://image.url/image.png"
      },
      logo_svg: {
        description: "Used as the SVG logo of the community",
        placeholder: "<svg ...></svg>"
      },
      secondary_logo_url: {
        description: "Used as the secondary logo",
        placeholder: "https://image.url"
      },
      left_navbar_svg_icon: {
        description: "The SVG icon used to expand the left navbar navigation menu. Should be a max of 24x24px.",
        placeholder: "<svg ...></svg>"
      },
      right_navbar_svg_icon: {
        description: "The SVG icon used to expand the right navbar navigation menu. Should be a max of 24x24px.",
        placeholder: "<svg ...></svg>"
      },
      mascot_user_id: {
        description: "User ID of the Mascot account",
        placeholder: "1"
      },
      mascot_image_url: {
        description: "Used as the mascot image.",
        placeholder: "https://image.url"
      },
      mascot_footer_image_url: {
        description: "Special cute mascot image used in the footer.",
        placeholder: "https://image.url"
      },
      mascot_image_description: {
        description: "Used as the alt text for the mascot image",
        placeholder: ""
      },
      meta_keywords: {
        description: "",
        placeholder: "List of valid keywords: comma separated, letters only e.g. engineering, development"
      },
      shop_url: {
        description: "Used as the shop url of the community",
        placeholder: "https://shop.url"
      },
      payment_pointer: {
        description: "Used for site-wide web monetization. " \
        "See: https://github.com/thepracticaldev/dev.to/pull/6345",
        placeholder: "$pay.somethinglikethis.co/value"
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
      onboarding_logo_image: {
        description: "Main onboarding display logo image",
        placeholder: "https://image.url"
      },
      onboarding_background_image: {
        description: "Background for onboarding splash page",
        placeholder: "https://image.url"
      },
      onboarding_taskcard_image: {
        description: "Used as the onboarding task-card image",
        placeholder: "https://image.url"
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
      twitter_hashtag: {
        description: "Used as the twitter hashtag of the community",
        placeholder: "#DEVCommunity"
      },
      sponsor_headline: {
        description: "Determines the heading text of the main sponsors sidebar above the list of sponsors.",
        placeholder: "Community Sponsors"
      },
      sidebar_tags: {
        description: "Determines which tags are shown on the homepage righthand sidebar",
        placeholder: "List of valid tags: comma separated, letters only e.g. help,discuss,explainlikeimfive,meta"
      },
      feed_style: {
        description: "Determines which default feed the users sees (rich content, more minimal, etc.)",
        placeholder: "basic, rich, or compact"
      },
      default_font: {
        description: "Determines the default Base Reading Font (registered users can change this in their UX settings)"
      }
      # Dynamic values ommitted: configurable_rate_limits and social_media_handles
    }.freeze
  end
end
