json.array! Comment.rooted_on(@commentable.id, @commentable_type).order("score DESC") do |comment|
  json.type_of            "comment"
  json.id_code            comment.id_code_generated
  json.body_html          comment.processed_html
  json.user do
    json.name             comment.user.name
    json.username         comment.user.username
    json.twitter_username comment.user.twitter_username
    json.github_username  comment.user.github_username
    json.website_url      comment.user.processed_website_url
    json.profile_image    ProfileImage.new(comment.user).get(640)
    json.profile_image_90 ProfileImage.new(comment.user).get(90)
  end
  json.children comment.children.order("score DESC").each do |comment|
    json.id_code            comment.id_code_generated
    json.body_html          comment.processed_html
    json.user do
      json.name             comment.user.name
      json.username         comment.user.username
      json.twitter_username comment.user.twitter_username
      json.github_username  comment.user.github_username
      json.website_url      comment.user.processed_website_url
      json.profile_image    ProfileImage.new(comment.user).get(640)
      json.profile_image_90 ProfileImage.new(comment.user).get(90)
    end
    json.children comment.children.order("score DESC").each do |comment|
      json.id_code            comment.id_code_generated
      json.body_html          comment.processed_html
      json.user do
        json.name             comment.user.name
        json.username         comment.user.username
        json.twitter_username comment.user.twitter_username
        json.github_username  comment.user.github_username
        json.website_url      comment.user.processed_website_url
        json.profile_image    ProfileImage.new(comment.user).get(640)
        json.profile_image_90 ProfileImage.new(comment.user).get(90)
      end
    end
  end
end
