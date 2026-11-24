content = @notification.json_data["admin_notification"] || {}
json.id @notification.id
json.user_id @notification.user_id
json.admin_notification_id @notification.notifiable_id
json.title content["title"]
json.body content["body"]
json.url content["url"]
json.read @notification.read
json.notified_at @notification.notified_at
