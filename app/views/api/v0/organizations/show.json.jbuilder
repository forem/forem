json.type_of "organization"

json.extract!(
  @organization,
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

json.joined_at @organization.created_at.strftime("%b %e, %Y")
json.profile_image Images::Profile.call(@organization.profile_image_url, length: 640)
