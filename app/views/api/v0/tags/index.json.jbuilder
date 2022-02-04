json.array! @tags.each do |tag|
  json.extract!(tag, :id, :name, :bg_color_hex, :text_color_hex, :short_summary)
end
