class ReactionImage
  attr_accessor :category

  def initialize(category)
    @category = category
  end

  def path
    images = {
      "like" => "heart-filled.svg",
      "unicorn" => "unicorn-filled.svg",
      "hands" => "emoji/emoji-one-hands.png",
      "thinking" => "emoji/emoji-one-thinking.png",
      "readinglist" => "save-filled.svg",
      "thumbsdown" => "emoji/emoji-one-thumbs-down.png",
      "vomit" => "emoji/emoji-one-nausea-face.png"
    }.freeze
    images[category]
  end
end
