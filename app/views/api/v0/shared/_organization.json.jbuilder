organization_profile_image = ProfileImage.new(organization)

json.organization do
  json.name             organization.name
  json.username         organization.username
  json.slug             organization.slug
  json.profile_image    organization_profile_image.get(width: 640)
  json.profile_image_90 organization_profile_image.get(width: 90)
end
