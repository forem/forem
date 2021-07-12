module DataUpdateScripts
  class WorkProfileFieldFollowUp
    OBSOLETE_FIELDS = %w[employer_name employer_url employment_title].freeze

    def run
      work_field = ProfileField.find_by(attribute_name: "work")
      if work_field
        work_group_id = ProfileFieldGroup.find_or_create_by(name: "Work").id
        work_field.update(profile_field_group_id: work_group_id)
      end
      ProfileField.destroy_by(attribute_name: OBSOLETE_FIELDS)
    end
  end
end
