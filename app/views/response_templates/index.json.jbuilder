json.array!(@response_templates) do |response_template|
  json.id response_template.id
  json.type_of response_template.type_of
  json.user_id response_template.user_id
  json.title response_template.title
  json.content response_template.content
  json.content_truncated truncate(response_template.content, length: 200)
end
