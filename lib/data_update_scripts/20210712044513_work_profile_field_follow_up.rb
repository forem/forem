module DataUpdateScripts
  class WorkProfileFieldFollowUp
    OBSOLETE_LABELS = ["Employer name", "Employer URL", "Employment title"].freeze

    def run
      ProfileField.destroy_by(label: OBSOLETE_LABELS)

      work_field = ProfileField.find_by(label: "Work")
      return unless work_field

      work_group = ProfileFieldGroup.find_by(name: "Work")
      return unless work_group

      work_field.update(profile_field_group_id: work_group.id)
    end
  end
end
