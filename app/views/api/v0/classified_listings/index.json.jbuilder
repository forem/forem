json.array! @classified_listings do |listing|
  json.type_of              "listings"
  json.id                   listing.id
  json.title                listing.title
  json.slug                 listing.slug
  json.body_markdown        listing.body_markdown
  json.bumped_at            listing.bumped_at
  json.cached_tag_list      listing.cached_tag_list
  json.category             listing.category
  json.contact_via_connect  listing.contact_via_connect
  json.processed_html       listing.processed_html
  json.published            listing.published
  json.slug                 listing.slug
  json.last_buffered        listing.last_buffered
  json.tag_list             listing.tag_list

  json.user do
    json.name             listing.user.name
    json.username         listing.user.username
    json.twitter_username listing.user.twitter_username
    json.github_username  listing.user.github_username
    json.website_url      listing.user.processed_website_url
    json.profile_image    ProfileImage.new(listing.user).get(640)
    json.profile_image_90 ProfileImage.new(listing.user).get(90)
  end

  if listing.organization
    json.organization do
      json.name             listing.organization.name
      json.username         listing.organization.username
      json.slug             listing.organization.slug
      json.profile_image    ProfileImage.new(listing.organization).get(640)
      json.profile_image_90 ProfileImage.new(listing.organization).get(90)
    end
  end
end
