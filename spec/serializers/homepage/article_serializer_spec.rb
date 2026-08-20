require "rails_helper"

RSpec.describe Homepage::ArticleSerializer, type: :serializer do
  describe "#serialized_collection_from" do
    let(:user) { create(:user, name: "\"Rowdy\" Roddy Piper \\:/") }
    let(:organization) { create(:organization) }
    let(:tag) { create(:tag, name: "ama", bg_color_hex: "#f3f3f3", text_color_hex: "#cccccc") }
    let(:article) { create(:article, user: user, organization: organization, tags: tag.name) }

    before do
      article
      stub_const("FlareTag::FLARE_TAG_IDS_HASH", { "ama" => tag.id })
    end

    it "is parseable as JSON (once converted to_json)" do
      response = described_class.serialized_collection_from(relation: Article.all)
      expect(JSON.parse(response.to_json)[0].dig("user", "name")).to eq(user.name)
    end

    it "includes who favorited the article" do
      leader = create(:user)
      article.update_columns(favorited_by_user_id: leader.id, favorited_at: Time.current)

      response = described_class.serialized_collection_from(relation: Article.all)

      expect(response.first[:favorited_by_user_id]).to eq(leader.id)
    end

    it "reports no favoriter for unfavorited articles" do
      response = described_class.serialized_collection_from(relation: Article.all)

      expect(response.first[:favorited_by_user_id]).to be_nil
    end
  end
end
