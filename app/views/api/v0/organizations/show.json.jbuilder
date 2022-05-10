json.type_of "organization"

json.extract!(
  @organization,
  :id,
  :username,
  :name,
  :summary,
  :twitter_username,
  :github_username,
  :url,
  :location,
  :tech_stack,
  :tag_line,
  :story,
)

json.joined_at utc_iso_timestamp(@organization.created_at)
json.profile_image @organization.profile_image_url_for(length: 640)
