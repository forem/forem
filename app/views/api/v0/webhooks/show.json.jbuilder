json.type_of "webhook_endpoint"

json.call(@webhook, :id, :source, :target_url, :events)

json.created_at @webhook.created_at.rfc3339

json.partial! "api/v0/shared/user", user: @webhook.user
