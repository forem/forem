json.type_of "webhook_endpoint"

json.call(@webhook, :id, :source, :target_url, :events, :created_at)

json.partial! "api/v0/articles/user", user: @webhook.user
