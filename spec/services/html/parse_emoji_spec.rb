require "rails_helper"

# rubocop:disable Rails/DynamicFindBy

RSpec.describe Html::ParseEmoji, type: :service do
  describe "#call" do
    it "converts emoji names wrapped in colons into unicode" do
      joy_emoji_unicode = Emoji.find_by_alias("joy").raw
      expect(described_class.call(":joy:")).to include(joy_emoji_unicode)
    end

    it "converts disability emojis as well", :aggregate_failures do
      disability_emojis = %w[
        guide_dog service_dog person_with_probing_cane man_with_probing_cane woman_with_probing_cane probing_cane
        person_in_motorized_wheelchair man_in_motorized_wheelchair woman_in_motorized_wheelchair
        person_in_manual_wheelchair man_in_manual_wheelchair woman_in_manual_wheelchair manual_wheelchair
        motorized_wheelchair wheelchair
      ]
      disability_emojis.each do |emoji|
        unicode = Emoji.find_by_alias(emoji).raw
        expect(described_class.call(":#{emoji}:")).to include(unicode)
      end
    end

    it "leaves original text between colons when no emoji is found" do
      emoji_text = ":no_one_will_ever_create_an_emoji_with_this_alias:"
      expect(described_class.call(emoji_text)).to include(emoji_text)
    end
  end
end

# rubocop:enable Rails/DynamicFindBy
