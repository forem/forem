module Html
  class ParseEmoji
    def self.call(html)
      return unless html

      html.gsub!(/:([\w+-]+):/) do |match|
        emoji = Emoji.find_by_alias(Regexp.last_match(1)) # rubocop:disable Rails/DynamicFindBy
        emoji.present? ? emoji.raw : match
      end
      html
    end
  end
end
