module DataUpdateScripts
  class RemoveProfileFieldUpdateScripts
    # these are safe to remove, because the seed data will have current values
    # and these largely predate selfhost. The attribute name api changed substantially
    # and reworking legacy scripts to match the refactor is higher cost than value
    FILE_NAMES = %w[
      20210108033107_remove_looking_for_work_profile_fields
      20210630034523_add_work_profile_field
      20210630063635_drop_profile_fields_for_static_attributes
      20210712044513_work_profile_field_follow_up
      20200826075937_migrate_profile_field_groups
    ].freeze

    def run
      DataUpdateScript.delete_by(file_name: FILE_NAMES)
    end
  end
end
