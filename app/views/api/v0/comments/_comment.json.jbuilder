json.type_of "comment"
json.id_code comment.id_code_generated

if comment.deleted?
  json.body_html "<p>[deleted]</p>"
  json.set! :user, {}
elsif comment.hidden_by_commentable_user?
  json.body_html "<p>[hidden by post author]</p>"
  json.set! :user, {}
else
  json.body_html comment.processed_html
  json.partial! "api/v0/shared/user", user: comment.user
end
