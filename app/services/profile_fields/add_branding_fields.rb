module ProfileFields
  class AddBrandingFields
    include FieldDefinition

    group "Branding" do
      field "Brand color 1",
            :color_field,
            placeholder: "#000000",
            description: "Used for backgrounds, borders etc.",
            display_area: "settings_only"
      field "Brand color 2",
            :color_field,
            placeholder: "#000000",
            description: "Used for texts (usually put on Brand color 1).",
            display_area: "settings_only"
    end
  end
end
