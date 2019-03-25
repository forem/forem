require "rails_helper"

RSpec.describe EmojiConverter do
  def convert_emoji(html)
    EmojiConverter.call(html)
  end

  describe "#convert" do
    it "converts emoji names wrapped in colons into unicode" do
      joy_emoji_unicode = Emoji.find_by_alias("joy").raw # rubocop:disable Rails/DynamicFindBy
      expect(convert_emoji(":joy:")).to include(joy_emoji_unicode)
    end

    it "leaves original text between colons when no emoji is found" do
      emoji_text = ":no_one_will_ever_create_an_emoji_with_this_alias:"
      expect(convert_emoji(emoji_text)).to include(emoji_text)
    end
  end
end
