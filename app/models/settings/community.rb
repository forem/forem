module Settings
  class Community < Base
    self.table_name = :settings_communities

    setting :copyright_start_year,
            type: :integer,
            default: ApplicationConfig["COMMUNITY_COPYRIGHT_START_YEAR"] || Time.zone.today.year
    setting :community_description, type: :string
    setting :community_emoji, type: :string, default: "🌱", validates: { emoji_only: true }
    setting :community_name, type: :string, default: ApplicationConfig["COMMUNITY_NAME"] || "New Forem"
    setting :member_label, type: :string, default: "user"
    setting :staff_user_id, type: :integer, default: 1
    setting :tagline, type: :string
  end
end
