json.organization do
  json.extract!(organization, :name, :username, :slug)

  json.profile_image    Images::Profile.call(organization.profile_image_url, length: 640)
  json.profile_image_90 Images::Profile.call(organization.profile_image_url, length: 90)
end
