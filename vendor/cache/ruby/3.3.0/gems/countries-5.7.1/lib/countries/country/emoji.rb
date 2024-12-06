# frozen_string_literal: true

module ISO3166
  module Emoji
    CODE_POINTS = {
      'a' => '🇦',
      'b' => '🇧',
      'c' => '🇨',
      'd' => '🇩',
      'e' => '🇪',
      'f' => '🇫',
      'g' => '🇬',
      'h' => '🇭',
      'i' => '🇮',
      'j' => '🇯',
      'k' => '🇰',
      'l' => '🇱',
      'm' => '🇲',
      'n' => '🇳',
      'o' => '🇴',
      'p' => '🇵',
      'q' => '🇶',
      'r' => '🇷',
      's' => '🇸',
      't' => '🇹',
      'u' => '🇺',
      'v' => '🇻',
      'w' => '🇼',
      'x' => '🇽',
      'y' => '🇾',
      'z' => '🇿'
    }.freeze

    # @return [String] the emoji flag for this country
    #
    # The emoji flag for this country, using Unicode Regional Indicator characters. e.g: "U+1F1FA U+1F1F8" for 🇺🇸
    def emoji_flag
      alpha2.downcase.chars.map { |c| CODE_POINTS[c] }.join
    end
  end
end
