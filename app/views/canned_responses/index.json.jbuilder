json.array!(@canned_responses) do |canned_response|
  json.id canned_response.id
  json.type_of canned_response.type_of
  json.user_id canned_response.user_id
  json.title canned_response.title
  json.content canned_response.content
  json.content_truncated truncate(canned_response.content, length: 200)
end
