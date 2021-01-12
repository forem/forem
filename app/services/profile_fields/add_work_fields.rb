module ProfileFields
  class AddWorkFields
    include FieldDefinition

    group "Work" do
      field "Education", :text_field, display_area: "header"
      field "Employer name", :text_field, placeholder: "Acme Inc.", display_area: "header"
      field "Employer URL", :text_field, placeholder: "https://dev.com", display_area: "settings_only"
      field "Employment title", :text_field, placeholder: "Junior Frontend Engineer", display_area: "header"
    end
  end
end
