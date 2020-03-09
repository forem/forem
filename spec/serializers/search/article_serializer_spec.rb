require "rails_helper"

RSpec.describe Search::ArticleSerializer do
  let(:user) { create(:user) }
  let(:organization) { create(:organization) }
  let(:tag) { create(:tag, name: "ama", bg_color_hex: "#f3f3f3", text_color_hex: "#cccccc") }
  let(:article) { create(:article, user: user, organization: organization, tags: tag.name) }

  it "serializes an article" do
    data_hash = described_class.new(article).serializable_hash.dig(:data, :attributes)
    user_data = Search::NestedUserSerializer.new(user).serializable_hash.dig(:data, :attributes)
    expect(data_hash[:user]).to eq(user_data)
    expect(data_hash.dig(:organization, :id)).to eq(organization.id)
    expect(data_hash.dig(:flare_tag_hash, :name)).to eq(tag.name)
    expect(data_hash.keys).to include(:id, :body_text, :hotness_score)
  end

  it "creates valid json for Elasticsearch", elasticsearch: true do
    data_hash = described_class.new(article).serializable_hash.dig(:data, :attributes)
    result = Article::SEARCH_CLASS.index(article.id, data_hash)
    expect(result["result"]).to eq("created")
  end
end
