json.array! @tags.each do |tag|
  json.extract!(tag, :id, :name, :bg_color_hex, :text_color_hex, :short_summary)
  json.badge do
    if tag.badge
      json.badge_image tag.badge.badge_image
    else
      json.badge_image nil
    end
  end
end
