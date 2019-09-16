json.array! @webhooks.each do |endpoint|
  json.type_of "webhook_endpoint"
  json.id             endpoint.id
  json.target_url     endpoint.target_url
  json.events         endpoint.events
  json.source         endpoint.source
  json.created_at     endpoint.created_at.rfc3339
  json.updated_at     endpoint.updated_at.rfc3339
end
