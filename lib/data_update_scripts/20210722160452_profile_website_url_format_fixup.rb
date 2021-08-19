module DataUpdateScripts
  class ProfileWebsiteUrlFormatFixup
    def run
      profiles_to_fix.each do |profile|
        fix_or_clear_website_url(profile)
        profile.save || log_failure(profile)
      end
    end

    def fix_or_clear_website_url(profile)
      profile.website_url =
        begin
          new_url = "https://#{profile.website_url.strip}"
          uri = URI.parse(new_url)
          if acceptable_uri?(uri)
            new_url
          else
            ""
          end
        rescue URI::InvalidURIError
          ""
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

    def acceptable_uri?(uri)
      uri.scheme.present? &&
        uri.host.present? &&
        uri.user.blank?
    end
  end
end
