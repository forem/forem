module DataUpdateScripts
  class FixDribbbleUrlProfileField
    def run
      old_field = ProfileField.find_by(attribute_name: "dribble_url")
      return unless old_field

      old_field.update(label: "Dribbble URL",
                       attribute_name: "dribbble_url",
                       placeholder_text: "https://dribbble.com/...")

      Profile.refresh_attributes!

      User.where.not(dribbble_url: [nil, ""]).find_each do |user|
        user.profile.update(dribbble_url: user.dribbble_url)
      end
    end
  end
end
