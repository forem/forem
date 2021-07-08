module DataUpdateScripts
  class DropProfileFieldsForStaticAttributes
    def run
      ProfileField.destroy_by(attribute_name: Profile.static_fields)
    end
  end
end
