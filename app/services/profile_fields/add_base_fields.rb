module ProfileFields
  class AddBaseFields < AddFields
    field "Name", :text_field, placeholder: "John Doe"
    field "Website URL", :text_field, placeholder: "https://yoursite.com"
    field "Summary", :text_area, placeholder: "A short bio..."
    field "Location", :text_field, placeholder: "Halifax, Nova Scotia"
  end
end
