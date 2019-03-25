require "rails_helper"

RSpec.describe FlareTag do
  let(:user) { create(:user) }
  let(:article) { create(:article, user_id: user.id) }

  describe "#flare_tag" do
    it "returns nil if there is no flare tag" do
      expect(described_class.new(article).tag).to be nil
    end

    it "returns a flare tag if there is a flare tag in the list" do
      valid_article = create(:article, tags: "ama")
      expect(described_class.new(valid_article).tag.name).to eq("ama")
    end

    it "returns nil if an except is provided" do
      valid_article = create(:article, tags: "explainlikeimfive")
      expect(described_class.new(valid_article, "explainlikeimfive").tag).to eq(nil)
    end

    it "returns a flare tag if there are 2 flare tags in the list" do
      valid_article = create(:article, tags: %w[ama explainlikeimfive])
      expect(described_class.new(valid_article).tag.name).to eq("explainlikeimfive")
    end
  end

  describe "#flare_tag_hash" do
    let(:tag) { create(:tag, name: "ama", bg_color_hex: "#f3f3f3", text_color_hex: "#cccccc") }
    let(:valid_article) { create(:article, tags: tag.name) }

    it "returns nil if an article doesn't have a flare tag" do
      expect(described_class.new(article).tag_hash).to be nil
    end

    it "returns a hash with the flare tag's name" do
      expect(described_class.new(valid_article).tag_hash.value?("ama")).to be true
    end

    it "returns a hash with the flare tag's bg_color_hex" do
      expect(described_class.new(valid_article).tag_hash.value?("#f3f3f3")).to be true
    end

    it "returns a hash with the flare tag's text_color_hex" do
      expect(described_class.new(valid_article).tag_hash.value?("#cccccc")).to be true
    end
  end
end
