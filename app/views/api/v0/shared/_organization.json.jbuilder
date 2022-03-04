json.organization do
  json.extract!(organization, :name, :username, :slug)

  json.profile_image    organization.profile_image_url_for(length: 640)
  json.profile_image_90 organization.profile_image_url_for(length: 90)
end
