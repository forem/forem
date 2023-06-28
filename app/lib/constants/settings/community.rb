module Constants
  module Settings
    module Community
      def self.details
        {
          community_description: {
            description: I18n.t("lib.constants.settings.community.description.description"),
            placeholder: I18n.t("lib.constants.settings.community.description.placeholder")
          },
          community_name: {
            description: I18n.t("lib.constants.settings.community.name.description"),
            placeholder: I18n.t("lib.constants.settings.community.name.placeholder")
          },
          copyright_start_year: {
            description: I18n.t("lib.constants.settings.community.copyright.description"),
            placeholder: Time.zone.today.year.to_s
          },
          member_label: {
            description: I18n.t("lib.constants.settings.community.member.description"),
            placeholder: I18n.t("lib.constants.settings.community.member.placeholder")
          },
          staff_user_id: {
            description: I18n.t("lib.constants.settings.community.staff.description"),
            placeholder: ""
          },
          tagline: {
            description: I18n.t("lib.constants.settings.community.tagline.description"),
            placeholder: I18n.t("lib.constants.settings.community.tagline.placeholder")
          }
        }
      end
    end
  end
end
