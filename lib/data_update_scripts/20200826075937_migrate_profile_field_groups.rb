module DataUpdateScripts
  class MigrateProfileFieldGroups
    def run
      # ensure we can run this after the group column gets removed
      return unless "group".in?(ProfileField.column_names)

      profile_field_groups = Hash.new do |hash, key|
        hash[key] = ProfileFieldGroup.find_or_create_by(name: key)
      end

      ProfileField.find_each do |profile_field|
        profile_field.update(profile_field_group: profile_field_groups[profile_field.group])
      end
    end
  end
end
