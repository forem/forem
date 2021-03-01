json.profile_field_groups do
  json.array!(@profile_field_groups) do |profile_field_group|
    json.extract!(
      profile_field_group,
      :id,
      :name,
      :description,
    )
    json.profile_fields(profile_field_group.profile_fields) do |profile_field|
      json.extract!(
        profile_field,
        :id,
        :attribute_name,
        :description,
        :input_type,
        :label,
        :placeholder_text,
      )
    end
  end
end
