json.type_of    "comment"

json.id_code    comment.id_code_generated
json.body_html  comment.processed_html

json.partial! "api/v0/shared/user", user: comment.user
