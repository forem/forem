json.type_of              "classified_listing"
json.id                   @classified_listing.id
json.title                @classified_listing.title
json.slug                 @classified_listing.slug
json.body_markdown        @classified_listing.body_markdown
json.bumped_at            @classified_listing.bumped_at
json.cached_tag_list      @classified_listing.cached_tag_list
json.category             @classified_listing.category
json.contact_via_connect  @classified_listing.contact_via_connect
json.processed_html       @classified_listing.processed_html
json.published            @classified_listing.published
json.slug                 @classified_listing.slug
json.last_buffered        @classified_listing.last_buffered
json.tag_list             @classified_listing.tag_list

json.user do
  json.name             @classified_listing.user.name
  json.username         @classified_listing.user.username
  json.twitter_username @classified_listing.user.twitter_username
  json.github_username  @classified_listing.user.github_username
  json.website_url      @classified_listing.user.processed_website_url
  json.profile_image    ProfileImage.new(@classified_listing.user).get(640)
  json.profile_image_90 ProfileImage.new(@classified_listing.user).get(90)
end

if @classified_listing.organization
  json.organization do
    json.name             @classified_listing.organization.name
    json.username         @classified_listing.organization.username
    json.slug             @classified_listing.organization.slug
    json.profile_image    ProfileImage.new(@classified_listing.organization).get(640)
    json.profile_image_90 ProfileImage.new(@classified_listing.organization).get(90)
  end
end
