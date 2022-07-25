module Constants
  module Settings
    module General
      IMAGE_PLACEHOLDER = "https://url/image.png".freeze

      def self.details
        {
          contact_email: {
            description: I18n.t("lib.constants.settings.general.contact_email.description"),
            placeholder: "hello@example.com"
          },
          credit_prices_in_cents: {
            small: {
              description: I18n.t("lib.constants.settings.general.credit.small.description"),
              placeholder: ""
            },
            medium: {
              description: I18n.t("lib.constants.settings.general.credit.medium.description"),
              placeholder: ""
            },
            large: {
              description: I18n.t("lib.constants.settings.general.credit.large.description"),
              placeholder: ""
            },
            xlarge: {
              description: I18n.t("lib.constants.settings.general.credit.xlarge.description"),
              placeholder: ""
            }
          },
          favicon_url: {
            description: I18n.t("lib.constants.settings.general.favicon.description"),
            placeholder: IMAGE_PLACEHOLDER
          },
          ga_tracking_id: {
            description: I18n.t("lib.constants.settings.general.ga_tracking.description"),
            placeholder: ""
          },
          ga_analytics_4_id: {
            description: I18n.t("lib.constants.settings.general.ga_analytics_4.description"),
            placeholder: ""
          },
          health_check_token: {
            description: I18n.t("lib.constants.settings.general.health.description"),
            placeholder: I18n.t("lib.constants.settings.general.health.placeholder")
          },
          logo_png: {
            description: I18n.t("lib.constants.settings.general.logo_png.description"),
            placeholder: IMAGE_PLACEHOLDER
          },
          logo_svg: {
            description: I18n.t("lib.constants.settings.general.logo_svg.description"),
            placeholder: IMAGE_PLACEHOLDER
          },
          main_social_image: {
            description: I18n.t("lib.constants.settings.general.main_social.description"),
            placeholder: IMAGE_PLACEHOLDER
          },
          mailchimp_api_key: {
            description: I18n.t("lib.constants.settings.general.mailchimp_api.description"),
            placeholder: ""
          },
          mailchimp_newsletter_id: {
            description: I18n.t("lib.constants.settings.general.mailchimp_news.description"),
            placeholder: ""
          },
          mailchimp_tag_moderators_id: {
            description: I18n.t("lib.constants.settings.general.mailchimp_tag_mod.description"),
            placeholder: ""
          },
          mailchimp_community_moderators_id: {
            description: I18n.t("lib.constants.settings.general.mailchimp_mod.description"),
            placeholder: ""
          },
          mascot_image_url: {
            description: I18n.t("lib.constants.settings.general.mascot_image.description"),
            placeholder: IMAGE_PLACEHOLDER
          },
          mascot_user_id: {
            description: I18n.t("lib.constants.settings.general.mascot_user.description"),
            placeholder: "1"
          },
          meta_keywords: {
            description: "",
            placeholder: I18n.t("lib.constants.settings.general.meta_keywords.description")
          },
          onboarding_background_image: {
            description: I18n.t("lib.constants.settings.general.onboarding.description"),
            placeholder: IMAGE_PLACEHOLDER
          },
          payment_pointer: {
            description: I18n.t("lib.constants.settings.general.payment.description"),
            placeholder: "$pay.somethinglikethis.co/value"
          },
          periodic_email_digest: {
            description: I18n.t("lib.constants.settings.general.periodic.description"),
            placeholder: 2
          },
          sidebar_tags: {
            description: I18n.t("lib.constants.settings.general.sidebar.description"),
            placeholder: I18n.t("lib.constants.settings.general.sidebar.placeholder")
          },
          sponsor_headline: {
            description: I18n.t("lib.constants.settings.general.sponsor.description"),
            placeholder: I18n.t("lib.constants.settings.general.sponsor.placeholder")
          },
          stripe_api_key: {
            description: I18n.t("lib.constants.settings.general.stripe_api.description"),
            placeholder: "sk_live_...."
          },
          stripe_publishable_key: {
            description: I18n.t("lib.constants.settings.general.stripe_key.description"),
            placeholder: "pk_live_...."
          },
          suggested_tags: {
            description: I18n.t("lib.constants.settings.general.tags.description"),
            placeholder: I18n.t("lib.constants.settings.general.tags.placeholder")
          },
          suggested_users: {
            description: I18n.t("lib.constants.settings.general.users.description"),
            placeholder: I18n.t("lib.constants.settings.general.users.placeholder")
          },
          prefer_manual_suggested_users: {
            description: I18n.t("lib.constants.settings.general.prefer_manual.description")
          },
          twitter_hashtag: {
            description: I18n.t("lib.constants.settings.general.hashtag.description"),
            placeholder: I18n.t("lib.constants.settings.general.hashtag.placeholder")
          },
          video_encoder_key: {
            description: I18n.t("lib.constants.settings.general.video.description"),
            placeholder: ""
          }
        }
      end
    end
  end
end
