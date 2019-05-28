json.array! @comments do |comment|
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

  json.children comment.children.order(score: :desc).each do |children_comment|
    json.id_code            children_comment.id_code_generated
    json.body_html          children_comment.processed_html
    json.user do
      json.name             children_comment.user.name
      json.username         children_comment.user.username
      json.twitter_username children_comment.user.twitter_username
      json.github_username  children_comment.user.github_username
      json.website_url      children_comment.user.processed_website_url
      json.profile_image    ProfileImage.new(children_comment.user).get(640)
      json.profile_image_90 ProfileImage.new(children_comment.user).get(90)
    end

    json.children children_comment.children.order(score: :desc).each do |grandchild_comment|
      json.id_code            grandchild_comment.id_code_generated
      json.body_html          grandchild_comment.processed_html
      json.user do
        json.name             grandchild_comment.user.name
        json.username         grandchild_comment.user.username
        json.twitter_username grandchild_comment.user.twitter_username
        json.github_username  grandchild_comment.user.github_username
        json.website_url      grandchild_comment.user.processed_website_url
        json.profile_image    ProfileImage.new(grandchild_comment.user).get(640)
        json.profile_image_90 ProfileImage.new(grandchild_comment.user).get(90)
      end
    end
  end
end
