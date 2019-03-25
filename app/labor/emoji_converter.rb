class EmojiConverter
  attr_reader :html

  def self.call(html)
    new(html).convert
  end

  def initialize(html)
    @html = html
  end

  def convert
    html.gsub!(/:([\w+-]+):/) do |match|
      emoji = Emoji.find_by_alias(Regexp.last_match(1)) # rubocop:disable Rails/DynamicFindBy
      emoji.present? ? emoji.raw : match
    end
    html
  end
end
