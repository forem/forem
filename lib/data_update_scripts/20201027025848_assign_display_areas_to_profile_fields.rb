module DataUpdateScripts
  class AssignDisplayAreasToProfileFields
    HEADER_FIELDS = %i[
      behance_url
      dribbble_url
      education
      employer_name
      employer_url
      employment_title
      facebook_url
      git_lab_url
      instagram_url
      linked_in_url
      location
      mastodon_url
      medium_url
      name
      stack_overflow_url
      twitch_url
      website_url
      youtube_url
      summary
    ].freeze

    SIDEBAR_FIELDS = %i[
      available_for
      currently_hacking_on
      currently_learning
      skills_languages
    ].freeze

    SETTINGS_FIELDS = %i[
      brand_color1
      brand_color2
      display_email_on_profile
      display_looking_for_work_on_profile
      looking_for_work
      recruiters_can_contact_me_about_job_opportunities
    ].freeze

    def run
      ProfileField.where(attribute_name: HEADER_FIELDS).update_all(display_area: :header)
      ProfileField.where(attribute_name: SIDEBAR_FIELDS).update_all(display_area: :left_sidebar)
      ProfileField.where(attribute_name: SETTINGS_FIELDS).update_all(display_area: :settings_only)
    end
  end
end
