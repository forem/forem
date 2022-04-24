require "rails_helper"

RSpec.describe FlareTag, type: :labor do
  let(:ama_tag) { create(:tag, name: "ama", bg_color_hex: "#f3f3f3", text_color_hex: "#cccccc") }
  let(:explainlikeimfive_tag) { create(:tag, name: "explainlikeimfive") }
  let(:user) { create(:user) }
  let(:article) { create(:article, user_id: user.id) }

  before do
    stub_const(
      "FlareTag::FLARE_TAG_IDS_HASH",
      { "ama" => ama_tag.id, "explainlikeimfive" => explainlikeimfive_tag.id },
    )
  end

  describe "#flare_tag" do
    it "returns nil if there is no flare tag" do
      expect(described_class.new(article).tag).to be_nil
    end

    it "returns a flare tag if there is a flare tag in the list" do
      valid_article = create(:article, tags: "ama")
      expect(described_class.new(valid_article).tag.name).to eq("ama")
    end

    it "returns nil if an except is provided" do
      valid_article = create(:article, tags: "explainlikeimfive")
      expect(described_class.new(valid_article, "explainlikeimfive").tag).to be_nil
    end

    it "returns first found flare tag if there are 2 flare tags in the list" do
      valid_article = create(:article, tags: %w[ama explainlikeimfive])
      expect(described_class.new(valid_article).tag.name).to eq("ama")
    end
  end

  describe "#tag_hash" do
    let(:valid_article) { create(:article, tags: ama_tag.name) }

    it "returns nil if an article doesn't have a flare tag" do
      expect(described_class.new(article).tag_hash).to be_nil
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
