module Constants
  ALLOWED_MASTODON_INSTANCES = [
    "101010.pl",
    "4estate.media",
    "acg.mn",
    "anarchism.space",
    "bitcoinhackers.org",
    "bsd.network",
    "chaos.social",
    "cmx.im",
    "cybre.space",
    "fosstodon.org",
    "framapiaf.org",
    "friends.nico",
    "functional.cafe",
    "hackers.town",
    "hearthtodon.com",
    "hex.bz",
    "horiedon.com",
    "hostux.social",
    "imastodon.net",
    "infosec.exchange",
    "kirakiratter.com",
    "knzk.me",
    "linuxrocks.online",
    "lou.lt",
    "mamot.fr",
    "mao.daizhige.org",
    "mastodon.art",
    "mastodon.at",
    "mastodon.blue",
    "mastodon.cloud",
    "mastodon.gamedev.place",
    "mastodon.host",
    "mastodon.online",
    "mastodon.sdf.org",
    "mastodon.social",
    "mastodon.technology",
    "mastodon.xyz",
    "mathtod.online",
    "merveilles.town",
    "mimumedon.com",
    "misskey.xyz",
    "moe.cat",
    "mstdn-workers.com",
    "mstdn.guru",
    "mstdn.io",
    "mstdn.jp",
    "mstdn.tokyocameraclub.com",
    "mstdn18.jp",
    "music.pawoo.net",
    "niu.moe",
    "noagendasocial.com",
    "octodon.social",
    "otajodon.com",
    "pawoo.net",
    "phpc.social",
    "qiitadon.com",
    "radical.town",
    "ro-mastodon.puyo.jp",
    "ruby.social",
    "ruhr.social",
    "social.coop",
    "social.targaryen.house",
    "social.tchncs.de",
    "switter.at",
    "todon.nl",
    "toot.cafe",
    "wikitetas.club",
    "xoxo.zone",
  ].freeze

  SITE_CONFIG_DETAILS = {
    authentication: {
      description: "How can users sign in?",
      placeholder: "",
    },
    campaign_hero_html_variant_name: {
      description: "Hero HtmlVariant name",
      placeholder: "",
    },
    campaign_articles_require_approval: {
      description: "",
      placeholder: "Campaign stories show up on sidebar with approval?",
    },
    campaign_sidebar_enabled: {
      description: "",
      placeholder: "Campaign sidebar enabled or not",
    },
    campaign_sidebar_image: {
      description: "https://image.url",
      placeholder: "Used at the top of the campaign sidebar",
    },
    campaign_featured_tags: {
      description: "Posts with which tags will be featured in the campaign sidebar (comma separated, letters only)",
      placeholder: "List of campaign tags: comma separated, letters only e.g. shecoded,theycoded",
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
      placeholder: "We're a place where coders share, stay up-to-date and grow their careers.",
    },
    main_social_image: {
      description: "Used as the main image in social networks and OpenGraph",
      placeholder: ""
    },
    logo_png: {
      description: "Minimum 1024px, used for PWA etc.",
      placeholder: "https://image.url/image.png"
    },
    mascot_user_id: {
      description: "User ID of the Mascot account",
      placeholder: "1"
    },
    mascot_image_url: {
      description: "Used as the mascot image.",
      placeholder: "https://image.url"
    },
    meta_keywords: {
      description: "",
      placeholder: ""
    },
    suggested_tags: {
      description: "Determines which tags are suggested to new users during onboarding (comma
        separated, letters only)",
      placeholder: "List of valid tags: comma separated, letters only e.g. beginners,javascript,ruby,swift,kotlin"
    },
    suggested_users: {
      description: "Determines which users are suggested to follow to new users during onboarding (comma
        separated, letters only). Please note that these users will be shown as a fallback if no recently-active commenters or producers can be suggested",
      placeholder: "List of valid usernames: comma separated, letters only e.g. ben,jess,peter,maestromac,andy,liana"
    }
  }.freeze
end
