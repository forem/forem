module ProfileFields
  class AddBrandingFields
    include FieldDefinition

    field "Brand color 1", :color_field, placeholder: "#000000", explanation: "Used for backgrounds, borders etc."
    field "Brand color 2",
          :color_field,
          placeholder: "#000000",
          explanation: "Used for texts (usually put on Brand color 1)."
  end
end
