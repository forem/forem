require "rails_helper"

RSpec.describe Homepage::FetchTagFlares, type: :service do
  describe ".call" do
    it "returns an empty hash if no flare tag is found" do
      articles = create_list(:article, 2, with_tags: false)

      result = described_class.call(articles)
      expect(result).to be_empty
    end

    it "returns the correct data structure for a flare tag", :aggregate_failures do
      bg_color_hex = "#ff0033"
      text_color_hex = "#00ff33"
      tag = create(:tag, name: Constants::Tags::FLARE_TAG_NAMES.first)
      tag.update(bg_color_hex: bg_color_hex, text_color_hex: text_color_hex)

      article1 = create(:article, tags: tag.name)
      article2 = create(:article, tags: "foobar")

      result = described_class.call([article1, article2])

      expect(result.size).to eq(1)
      expect(result.keys.first).to eq(article1.id)
      expected_result = { "bg_color_hex" => bg_color_hex, "text_color_hex" => text_color_hex, "name" => tag.name }
      expect(result[article1.id]).to eq(expected_result)
    end
  end
end
