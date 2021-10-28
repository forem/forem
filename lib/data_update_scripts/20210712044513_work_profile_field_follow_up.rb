module DataUpdateScripts
  class WorkProfileFieldFollowUp
    OBSOLETE_FIELDS = %w[employer_name employer_url employment_title].freeze

    def run
      ProfileField.destroy_by(attribute_name: OBSOLETE_FIELDS)

      work_field = ProfileField.find_by(attribute_name: "work")
      return unless work_field

      work_group = ProfileFieldGroup.find_by(name: "Work")
      return unless work_group

      work_field.update(profile_field_group_id: work_group.id)
    end
  end
end
