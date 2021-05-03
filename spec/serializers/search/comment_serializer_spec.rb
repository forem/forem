require "rails_helper"

RSpec.describe Search::CommentSerializer do
  let(:user) { create(:user) }
  let(:article) { create(:article, user: user) }
  let(:comment) { create(:comment, user: user, commentable: article) }

  it "serializes an comment" do
    data_hash = described_class.new(comment).serializable_hash.dig(:data, :attributes)
    user_data = Search::NestedUserSerializer.new(user).serializable_hash.dig(:data, :attributes)
    expect(data_hash[:user]).to eq(user_data)
    expect(data_hash.keys).to include(:id, :body_text, :hotness_score, :title)
  end
end
