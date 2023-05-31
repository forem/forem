json.array! @suggestions.each do |suggested|
  json.extract!(suggested, :id, :name, :username, :type_identifier)

  json.summary           truncate(suggested.tag_line || t("json.author", community: community_name), length: 100)
  json.profile_image_url suggested.profile_image_url_for(length: 90)
  json.following         false
end
