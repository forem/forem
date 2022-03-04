json.type_of "profile_image"

json.image_of @profile_image_owner.class.name.downcase
json.profile_image @profile_image_owner.profile_image_url_for(length: 640)
json.profile_image_90 @profile_image_owner.profile_image_url_for(length: 90)
