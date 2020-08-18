module Profiles
  module ExtractData
    DIRECT_ATTRIBUTES = %i[
      available_for
      behance_url
      currently_hacking_on
      currently_learning
      dribble_url
      education
      employer_name
      employer_url
      employment_title
      facebook_url
      instagram_url
      location
      looking_for_work
      mastodon_url
      medium_url
      mostly_work_with
      name
      summary
      twitch_url
      website_url
      youtube_url
    ].freeze

    MAPPED_ATTRIBUTES = {
      brand_color1: :bg_color_hex,
      brand_color2: :text_color_hex,
      display_email_on_profile: :email_public,
      display_looking_for_work_on_profile: :looking_for_work_publicly,
      git_lab_url: :gitlab_url,
      linked_in_url: :linkedin_url,
      recruiters_can_contact_me_about_job_opportunities: :contact_consent,
      stack_overflow_url: :stackoverflow_url
    }.freeze

    def self.call(user)
      user_attributes = user.attributes.symbolize_keys!

      direct_data = user_attributes.extract!(*DIRECT_ATTRIBUTES)
      mapped_data = MAPPED_ATTRIBUTES.keys.zip(user_attributes.values_at(*MAPPED_ATTRIBUTES.values)).to_h

      direct_data.merge(mapped_data)
    end
  end
end
