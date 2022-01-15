module Constants
  module Settings
    module General
      IMAGE_PLACEHOLDER = "https://url/image.png".freeze
      SVG_PLACEHOLDER = "<svg ...></svg>".freeze

      def self.details
        {
          credit_prices_in_cents: {
            small: {
              description: I18n.t("lib.constants.settings.general.price_for_small_credit_pur"),
              placeholder: ""
            },
            medium: {
              description: I18n.t("lib.constants.settings.general.price_for_medium_credit_pu"),
              placeholder: ""
            },
            large: {
              description: I18n.t("lib.constants.settings.general.price_for_large_credit_pur"),
              placeholder: ""
            },
            xlarge: {
              description: I18n.t("lib.constants.settings.general.price_for_extra_large_cred"),
              placeholder: ""
            }
          },
          favicon_url: {
            description: I18n.t("lib.constants.settings.general.used_as_the_site_favicon"),
            placeholder: IMAGE_PLACEHOLDER
          },
          ga_tracking_id: {
            description: I18n.t("lib.constants.settings.general.google_analytics_tracking"),
            placeholder: ""
          },
          health_check_token: {
            description: I18n.t("lib.constants.settings.general.used_to_authenticate_with"),
            placeholder: I18n.t("lib.constants.settings.general.a_secure_token")
          },
          logo_png: {
            description: I18n.t("lib.constants.settings.general.used_as_a_fallback_to_the"),
            placeholder: IMAGE_PLACEHOLDER
          },
          logo_svg: {
            description: I18n.t("lib.constants.settings.general.used_as_the_svg_logo_of_th"),
            placeholder: SVG_PLACEHOLDER
          },
          main_social_image: {
            description: I18n.t("lib.constants.settings.general.used_as_the_main_image_in"),
            placeholder: IMAGE_PLACEHOLDER
          },
          mailchimp_api_key: {
            description: I18n.t("lib.constants.settings.general.api_key_used_to_connect_ma"),
            placeholder: ""
          },
          mailchimp_newsletter_id: {
            description: I18n.t("lib.constants.settings.general.main_newsletter_id_also_kn"),
            placeholder: ""
          },
          mailchimp_sustaining_members_id: {
            description: I18n.t("lib.constants.settings.general.sustaining_members_newslet"),
            placeholder: ""
          },
          mailchimp_tag_moderators_id: {
            description: I18n.t("lib.constants.settings.general.tag_moderators_newsletter"),
            placeholder: ""
          },
          mailchimp_community_moderators_id: {
            description: I18n.t("lib.constants.settings.general.community_moderators_newsl"),
            placeholder: ""
          },
          mascot_image_url: {
            description: I18n.t("lib.constants.settings.general.used_as_the_mascot_image"),
            placeholder: IMAGE_PLACEHOLDER
          },
          mascot_user_id: {
            description: I18n.t("lib.constants.settings.general.user_id_of_the_mascot_acco"),
            placeholder: "1"
          },
          meta_keywords: {
            description: "",
            placeholder: I18n.t("lib.constants.settings.general.list_of_valid_keywords_com")
          },
          onboarding_background_image: {
            description: I18n.t("lib.constants.settings.general.background_for_onboarding"),
            placeholder: IMAGE_PLACEHOLDER
          },
          payment_pointer: {
            description: I18n.t("lib.constants.settings.general.used_for_site_wide_web_mon"),
            placeholder: "$pay.somethinglikethis.co/value"
          },
          periodic_email_digest: {
            description: I18n.t("lib.constants.settings.general.determines_how_often_perio"),
            placeholder: 2
          },
          sidebar_tags: {
            description: I18n.t("lib.constants.settings.general.determines_which_tags_are"),
            placeholder: I18n.t("lib.constants.settings.general.list_of_valid_comma_separa")
          },
          sponsor_headline: {
            description: I18n.t("lib.constants.settings.general.determines_the_heading_tex"),
            placeholder: I18n.t("lib.constants.settings.general.community_sponsors")
          },
          stripe_api_key: {
            description: I18n.t("lib.constants.settings.general.secret_stripe_key_for_rece"),
            placeholder: "sk_live_...."
          },
          stripe_publishable_key: {
            description: I18n.t("lib.constants.settings.general.public_stripe_key_for_rece"),
            placeholder: "pk_live_...."
          },
          suggested_tags: {
            description: I18n.t("lib.constants.settings.general.determines_which_tags_are2"),
            placeholder: I18n.t("lib.constants.settings.general.list_of_valid_tags_comma_s")
          },
          suggested_users: {
            description: I18n.t("lib.constants.settings.general.determines_which_users_are"),
            placeholder: I18n.t("lib.constants.settings.general.list_of_valid_usernames_co")
          },
          prefer_manual_suggested_users: {
            description: I18n.t("lib.constants.settings.general.always_show_suggested_user")
          },
          twitter_hashtag: {
            description: I18n.t("lib.constants.settings.general.used_as_the_twitter_hashta"),
            placeholder: I18n.t("lib.constants.settings.general.devcommunity")
          },
          video_encoder_key: {
            description: I18n.t("lib.constants.settings.general.secret_key_used_to_allow_a"),
            placeholder: ""
          }
        }
      end
    end
  end
end
