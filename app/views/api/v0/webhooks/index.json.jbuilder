json.array! @webhooks.each do |endpoint|
  json.type_of        "webhook_endpoint"
  json.id             endpoint.id
  json.source         endpoint.source
  json.target_url     endpoint.target_url
  json.events         endpoint.events
  json.created_at     endpoint.created_at.rfc3339
end
