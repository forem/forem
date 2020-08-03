module ProfileFields
  class AddBaseFields < AddFields
    field "Name", :text_field, "John Doe"
    field "Website URL", :text_field, "https://yoursite.com"
    field "Summary", :text_area, "A short bio..."
    field "Location", :text_field, "Halifax, Nova Scotia"
  end
end
