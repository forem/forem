module DataUpdateScripts
  SETTINGS = %w[
    community_description
    community_emoji
    community_name
    staff_user_id
    tagline
  ].freeze

  class MoveCommunitySettings
    def run
      return if Settings::Community.any?

      SETTINGS.each do |setting|
        Settings::Community.public_send("#{setting}=", SiteConfig.public_send(setting))
      end

      # These two settings have been renamed
      Settings::Community.copyright_start_year = SiteConfig.community_copyright_start_year
      Settings::Community.member_label = SiteConfig.community_member_label
    end
  end
end
