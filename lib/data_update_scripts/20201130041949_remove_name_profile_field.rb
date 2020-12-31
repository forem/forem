module DataUpdateScripts
  class RemoveNameProfileField
    def run
      ProfileField.find_by(attribute_name: :name)&.destroy
    end
  end
end
