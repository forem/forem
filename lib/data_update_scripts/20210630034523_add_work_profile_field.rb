module DataUpdateScripts
  class AddWorkProfileField
    def run
      ProfileField.find_or_create_by(
        label: "Work",
        placeholder_text: "What do you do? Example: Software Engineer at Forem",
        input_type: :text_field,
        display_area: :header,
      )
    end
  end
end
