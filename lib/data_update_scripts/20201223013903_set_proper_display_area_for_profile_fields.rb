module DataUpdateScripts
  class SetProperDisplayAreaForProfileFields
    def run
      ProfileField.where(attribute_name: %w[brand_color1
                                            brand_color2
                                            recruiters_can_contact_me_about_job_opportunities
                                            display_email_on_profile
                                            twitter_url
                                            github_url
                                            facebook_url
                                            linkedin_url
                                            youtube_url
                                            instagram_url
                                            behance_url
                                            medium_url
                                            stackoverflow_url
                                            gitlab_url
                                            twitch_url
                                            mastodon_url
                                            website_url])
        .update_all(display_area: "settings_only")
      ProfileField.where.not(display_area: "settings_only").update_all(display_area: "header")
      ProfileField.where(attribute_name:
        %w[currently_hacking_on currently_learning mostly_work_with available_for])
        .update_all(display_area: "left_sidebar")
    end
  end
end
