module DataUpdateScripts
  class MoveUserExperienceSettings
    def run
      return if Settings::UserExperience.any?

      Settings::UserExperience.editable_keys.each do |field|
        Settings::UserExperience.public_send("#{field}=", Settings::General.public_send(field))
      end
    end
  end
end
