json.type_of            "webhook_endpoint"
json.events             @webhook.events
json.target_url         @webhook.target_url
json.source             @webhook.source

json.partial! "api/v0/articles/user", user: @webhook.user
