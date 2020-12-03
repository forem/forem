module ProfileFields
  class AddBaseFields
    include FieldDefinition

    group "Basic" do
      field "Display email on profile", :check_box, display_area: "settings_only"
      field "Website URL", :text_field, placeholder: "https://yoursite.com", display_area: "header"
      field "Summary", :text_area, placeholder: "A short bio...", display_area: "header"
      field "Location", :text_field, placeholder: "Halifax, Nova Scotia", display_area: "header"
    end
  end
end
