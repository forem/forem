module DataUpdateScripts
  class RemoveCheckboxTypeFromProfileFields
    def run
      # check boxes become inputs
      ProfileField.where(input_type: 2).update(input_type: 0)
    end
  end
end
