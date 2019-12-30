json.array!(@canned_responses) do |canned_response|
  json.id canned_response.id
  # json.user_id canned_response.user_id
  json.title canned_response.title
  json.titleTruncated truncate(canned_response.title, length: 20)
  json.content canned_response.content
  json.contentTruncated truncate(canned_response.content, length: 20)
end
