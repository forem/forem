json.array! @followed_tags do |follow|
  json.type_of                 "tag_following"
  json.id                      follow.id
  json.name                    follow.followable.name
  json.points                  follow.points
  json.token                   form_authenticity_token
  json.color                   HexComparer.new([follow.followable.bg_color_hex || "#0000000", follow.followable.text_color_hex || "#ffffff"]).brightness(0.8)
end
