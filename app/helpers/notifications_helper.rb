module NotificationsHelper
  REACTION_IMAGES = {
    "like" => "heart-filled.svg",
    "unicorn" => "unicorn-filled.svg",
    "hands" => "twemoji/hands.svg",
    "thinking" => "twemoji/thinking.svg",
    "readinglist" => "save-filled.svg",
    "thumbsdown" => "twemoji/thumb-down.svg",
    "vomit" => "twemoji/suspicious.svg"
  }.freeze

  def reaction_image(category)
    REACTION_IMAGES[category]
  end
end
