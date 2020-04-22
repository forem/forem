json.array! @webhooks.each do |endpoint|
  json.type_of "webhook_endpoint"

  json.extract!(endpoint, :id, :source, :target_url, :events, :created_at)
end
