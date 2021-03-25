json.array! @followed_tags do |follow|
  followable = follow.followable
  colors = [followable.bg_color_hex || "#000000", followable.text_color_hex || "#ffffff"]

  json.type_of "tag_following"
  json.extract!(follow, :id, :points)

  json.name         followable.name
  json.token        form_authenticity_token
  json.color        Color::CompareHex.new(colors).brightness(0.8)
end
