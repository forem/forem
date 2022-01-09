module Constants
  module Settings
    module Community
      def self.details
        {
          community_description: {
            description: I18n.t("lib.constants.settings.community.used_in_meta_description_t"),
            placeholder: I18n.t("lib.constants.settings.community.a_fabulous_community_of_ki")
          },
          community_emoji: {
            description: I18n.t("lib.constants.settings.community.used_in_the_title_tags_acr"),
            placeholder: ""
          },
          community_name: {
            description: I18n.t("lib.constants.settings.community.used_as_the_primary_name_f"),
            placeholder: I18n.t("lib.constants.settings.community.new_forem")
          },
          copyright_start_year: {
            description: I18n.t("lib.constants.settings.community.used_to_mark_the_year_this"),
            placeholder: Time.zone.today.year.to_s
          },
          member_label: {
            description: I18n.t("lib.constants.settings.community.used_to_determine_what_a_m"),
            placeholder: I18n.t("lib.constants.settings.community.user")
          },
          staff_user_id: {
            description: I18n.t("lib.constants.settings.community.account_id_which_acts_as_a"),
            placeholder: ""
          },
          tagline: {
            description: I18n.t("lib.constants.settings.community.used_in_signup_modal"),
            placeholder: I18n.t("lib.constants.settings.community.we_re_a_place_where_coders")
          }
        }
      end
    end
  end
end
