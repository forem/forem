module ProfileFields
  class AddWorkFields
    include FieldDefinition

    group "Work" do
      field "Education", :text_field
      field "Employer name", :text_field, placeholder: "Acme Inc."
      field "Employer URL", :text_field, placeholder: "https://dev.com"
      field "Employment title", :text_field, placeholder: "Junior Frontend Engineer"
      field "Looking for work", :check_box
      field 'Display "looking for work" on profile', :check_box
      field "Recruiters can contact me about job opportunities", :check_box
    end
  end
end
