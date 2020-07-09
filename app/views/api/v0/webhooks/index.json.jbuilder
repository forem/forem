json.array! @webhooks.each do |endpoint|
  json.type_of "webhook_endpoint"

  json.extract!(endpoint, :id, :source, :target_url, :events)

  json.created_at endpoint.created_at.rfc3339
end
