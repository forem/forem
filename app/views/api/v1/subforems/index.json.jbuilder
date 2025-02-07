json.array! @subforems do |subforem|
  json.domain           subforem.domain
  json.root             subforem.root
  json.name             Settings::Community.community_name(subforem_id: subforem.id)
  json.description      Settings::Community.community_description(subforem_id: subforem.id)
  json.logo_image_url   Settings::General.logo_png(subforem_id: subforem.id)
  json.cover_image_url  Settings::General.main_social_image
end

