module DataUpdateScripts
  class RemoveLookingForWorkProfileFields
    def run
      # destroy_by is idempotent by default: if no record can be found an empty
      # array will be returned.
      ProfileField.destroy_by(attribute_name: "looking_for_work")
      ProfileField.destroy_by(attribute_name: "display_looking_for_work_on_profile")
    end
  end
end
