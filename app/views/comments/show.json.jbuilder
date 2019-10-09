json.status                "created"
json.css                   @comment.custom_css
json.depth                 @comment.depth
json.url                   @comment.path
json.readable_publish_date @comment.readable_publish_date
json.published_timestamp   @comment.decorate.published_timestamp
json.body_html             @comment.processed_html
json.id                    @comment.id
json.id_code               @comment.id_code_generated
json.newly_created         true
json.user do
  json.id               @comment.user.id
  json.username         @comment.user.username
  json.name             @comment.user.name
  json.profile_pic      ProfileImage.new(@comment.user).get(50)
  json.twitter_username @comment.user.twitter_username
  json.github_username  @comment.user.github_username
end
