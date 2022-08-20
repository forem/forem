module DataUpdateScripts
  class RemoveUnusedProfileFields
    OBSOLETE_FIELDS = %w[
      behance_url
      brand_color1
      brand_color2
      display_email_on_profile
      dribbble_url
      facebook_url
      git_lab_url
      instagram_url
      linked_in_url
      mastodon_url
      medium_url
      recruiters_can_contact_me_about_job_opportunities
      stack_overflow_url
      twitch_url
      youtube_url
    ].freeze

    def run
      ProfileField.destroy_by(attribute_name: OBSOLETE_FIELDS)
    end
  end
end
