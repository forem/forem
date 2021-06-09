module DataUpdateScripts
  class MoveSummaryWebsiteUrlAndLocationToProfile
    def run
      Profile.select(:id,
                     :user_id,
                     "data->'summary' as data_summary",
                     "data->'location' as data_location",
                     "data->'website_url' as data_website_url").find_each do |profile|
        profile.update_columns(summary: profile.data_summary,
                               location: profile.data_location,
                               website_url: profile.data_website_url)
      end
    end
  end
end
