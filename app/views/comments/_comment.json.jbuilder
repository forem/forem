json.status "created"
json.css @comment.custom_css
json.depth @comment.depth
json.url @comment.path
json.readable_publish_date @comment.readable_publish_date
json.published_timestamp @comment.decorate.published_timestamp
json.public_reactions_count @comment.public_reactions_count.to_i
json.body_html @comment.processed_html
json.id @comment.id
json.id_code @comment.id_code_generated
json.newly_created true
json.user do
  json.id current_user.id
  json.username current_user.username
  json.name current_user.name
  json.profile_pic current_user.profile_image_url_for(length: 50)
  json.twitter_username current_user.twitter_username
  json.github_username current_user.github_username
end
