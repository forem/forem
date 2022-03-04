json.array!(@response_templates) do |response_template|
  json.extract!(
    response_template,
    :id,
    :type_of,
    :user_id,
    :title,
    :content,
  )
end
