json.type_of "profile_image"

json.image_of @profile_image_owner.class.name.downcase
json.profile_image Images::Profile.call(@profile_image_owner.profile_image_url, length: 640)
json.profile_image_90 Images::Profile.call(@profile_image_owner.profile_image_url, length: 90)
