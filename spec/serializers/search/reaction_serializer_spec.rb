require "rails_helper"

RSpec.describe Search::ReactionSerializer do
  let(:user) { create(:user) }
  let(:tag) { create(:tag, name: "ama") }
  let(:article) { create(:article, user: user, tags: tag.name) }
  let(:comment) { create(:comment, user: user, commentable: article) }
  let(:article_reaction) { create(:reaction, reactable: article, user: user) }
  let(:comment_reaction) { create(:reaction, reactable: comment, user: user) }

  it "serializes an article reaction" do
    data_hash = described_class.new(article_reaction).serializable_hash.dig(:data, :attributes)
    user_data = Search::NestedUserSerializer.new(user).serializable_hash.dig(:data, :attributes)
    expect(data_hash.dig(:reactable, :user)).to eq(user_data)
    expect(data_hash.dig(:reactable).keys).to include(:id, :body_text, :class_name, :path, :tags, :title)
    expect(data_hash.keys).to include(:id, :category, :status, :user_id)
  end

  it "serializes a comment reaction" do
    data_hash = described_class.new(comment_reaction).serializable_hash.dig(:data, :attributes)
    user_data = Search::NestedUserSerializer.new(user).serializable_hash.dig(:data, :attributes)
    expect(data_hash.dig(:reactable, :user)).to eq(user_data)
    expect(data_hash.dig(:reactable).keys).to include(:id, :body_text, :class_name, :path, :tags, :title)
    expect(data_hash.keys).to include(:id, :category, :status, :user_id)
  end

  it "creates valid json for Elasticsearch" do
    data_hash = described_class.new(article_reaction).serializable_hash.dig(:data, :attributes)
    result = Reaction::SEARCH_CLASS.index(article.id, data_hash)
    expect(result["result"]).to eq("created")
  end
end
