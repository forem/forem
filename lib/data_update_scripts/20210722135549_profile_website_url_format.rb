module DataUpdateScripts
  class ProfileWebsiteUrlFormat
    def run
      profiles_to_fix.each do |profile|
        fix_or_clear_website_url(profile)
        profile.save || log_failure(profile)
      end
    end

    def fix_or_clear_website_url(profile)
      profile.website_url =
        begin
          new_url = "https://#{profile.website_url}"
          uri = URI.parse(new_url)
          uri.scheme.present? && uri.host.present? && new_url || ""
        end
    end

    def log_failure(profile)
      Rails.logger.warn("Attempted to update website_url for profile #{profile.id} but failed with #{profile.errors}")
    end

    def profiles_to_fix
      Profile
        .where.not("website_url like 'http__/%'")
        .where.not(website_url: [nil, ""])
    end
  end
end
