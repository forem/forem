module NotificationsHelper
  REACTION_IMAGES = {
    "like" => "heart-filled.svg",
    "unicorn" => "unicorn-filled.svg",
    "hands" => "emoji/emoji-one-hands.png",
    "thinking" => "emoji/emoji-one-thinking.png",
    "readinglist" => "save-filled.svg",
    "thumbsdown" => "emoji/emoji-one-thumbs-down.png",
    "vomit" => "emoji/emoji-one-nausea-face.png"
  }.freeze

  def reaction_image(category)
    REACTION_IMAGES[category]
  end
end
