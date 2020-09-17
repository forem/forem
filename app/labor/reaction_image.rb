class ReactionImage
  attr_accessor :category

  def initialize(category)
    @category = category
  end

  def path
    images = {
      "like" => "emoji/emoji-one-heart.png",
      "unicorn" => "emoji/emoji-one-unicorn.png",
      "hands" => "emoji/emoji-one-hands.png",
      "thinking" => "emoji/emoji-one-thinking.png",
      "readinglist" => "emoji/emoji-one-bookmark.png",
      "thumbsdown" => "emoji/emoji-one-thumbs-down.png",
      "vomit" => "emoji/emoji-one-nausea-face.png"
    }.freeze
    images[category]
  end
end
