json.type_of            "article"
json.id                 @article.id
json.title              @article.title
json.description        @article.description
json.cover_image        @article.main_image
json.published_at       @article.published_at
json.social_image       cloud_social_image(@article)
json.tag_list           @article.tag_list
json.slug               @article.slug
json.path               @article.path
json.url                @article.url
json.canonical_url      @article.processed_canonical_url
json.comments_count     @article.comments_count
json.positive_reactions_count    @article.positive_reactions_count

json.body_html          @article.processed_html
json.ltag_style         @article.liquid_tags_used.map { |ltag| Rails.application.assets["ltags/#{ltag}.css"].to_s.html_safe }
json.ltag_script        @article.liquid_tags_used.map { |ltag| ltag.script.html_safe }

json.user do
  json.name @article.user.name
  json.username @article.user.username
  json.twitter_username @article.user.twitter_username
  json.github_username  @article.user.github_username
  json.website_url      @article.user.processed_website_url
  json.profile_image    ProfileImage.new(@article.user).get(640)
  json.profile_image_90 ProfileImage.new(@article.user).get(90)
end
