json.array! @followed_tags do |follow|
  followable = follow.followable
  colors = [followable.bg_color_hex || "#000000", followable.text_color_hex || "#ffffff"]

  json.type_of "tag_following"
  json.extract!(follow, :id, :points, :explicit_points)

  json.taggings_count followable.taggings_count
  json.name           followable.name
  json.token          form_authenticity_token
  json.short_summary  sanitize(followable.short_summary)
  json.color          Color::CompareHex.new(colors).brightness(0.8)
  json.tag_id         followable.id
end
