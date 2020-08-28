organization_profile_image = Images::Avatar.call(organization.profile_image_url)

json.organization do
  json.extract!(organization, :name, :username, :slug)

  json.profile_image    organization_profile_image.get(width: 640)
  json.profile_image_90 organization_profile_image.get(width: 90)
end
