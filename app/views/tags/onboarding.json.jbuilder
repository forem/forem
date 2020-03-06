json.array! @tags.each do |tag|
  json.id               tag.id
  json.name             tag.name
  json.bg_color_hex     tag.bg_color_hex
  json.text_color_hex   tag.text_color_hex
  json.following        nil
end
