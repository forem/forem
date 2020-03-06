require "rails_helper"

RSpec.describe Search::ArticleSerializer do
  let(:user) { create(:user) }
  let(:organization) { create(:organization) }
  let(:article) { create(:article, user: user, organization: organization) }

  it "serializes an article" do
    data_hash = described_class.new(article).serializable_hash.dig(:data, :attributes)
    user_data = Search::NestedUserSerializer.new(user).serializable_hash.dig(:data, :attributes)
    expect(data_hash[:user]).to eq(user_data)
    expect(data_hash.dig(:organization, :id)).to eq(organization.id)
    expect(data_hash.keys).to include(:id, :body_text, :hotness_score)
  end
end
