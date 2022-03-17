module Settings
  class Community < Base
    self.table_name = :settings_communities

    setting :copyright_start_year,
            type: :integer,
            default: ApplicationConfig["COMMUNITY_COPYRIGHT_START_YEAR"] || Time.zone.today.year
    setting :community_description, type: :string
    setting(
      :community_name,
      type: :string,
      default: ApplicationConfig["COMMUNITY_NAME"] || I18n.t("models.settings.community.new_forem"),
      validates: {
        format: {
          with: /\A[^[<|>]]+\Z/,
          message: I18n.t("models.settings.community.message")
        }
      },
    )
    setting :member_label, type: :string, default: "user"
    setting :staff_user_id, type: :integer, default: 1
    setting :tagline, type: :string
  end
end
