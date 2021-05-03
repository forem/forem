module Constants
  module Settings
    module Community
      DETAILS = {
        community_description: {
          description: "Used in meta description tags etc.",
          placeholder: "A fabulous community of kind and welcoming people."
        },
        community_emoji: {
          description: "Used in the title tags across the site alongside the community name",
          placeholder: ""
        },
        community_name: {
          description: "Used as the primary name for your Forem, e.g. DEV, DEV Community, The DEV Community, etc.",
          placeholder: "New Forem"
        },
        copyright_start_year: {
          description: "Used to mark the year this forem was started.",
          placeholder: Time.zone.today.year.to_s
        },
        member_label: {
          description: "Used to determine what a member will be called e.g developer, hobbyist etc.",
          placeholder: "user"
        },
        staff_user_id: {
          description: "Account ID which acts as automated 'staff'— used principally for welcome thread.",
          placeholder: ""
        },
        tagline: {
          description: "Used in signup modal.",
          placeholder: "We're a place where coders share, stay up-to-date and grow their careers."
        }
      }.freeze
    end
  end
end
