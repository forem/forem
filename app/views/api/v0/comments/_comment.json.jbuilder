json.type_of "comment"
json.id_code comment.id_code_generated

if comment.deleted?
  json.body_html "<p>#{Comment::TITLE_DELETED}</p>"
  json.set! :user, {}
elsif comment.hidden_by_commentable_user?
  json.body_html "<p>#{Comment::TITLE_HIDDEN}</p>"
  json.set! :user, {}
else
  json.body_html comment.processed_html
  json.partial! "api/v0/shared/user", user: comment.user
end
