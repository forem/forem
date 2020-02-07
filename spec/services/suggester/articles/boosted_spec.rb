require "rails_helper"

RSpec.describe Suggester::Articles::Boosted, type: :service do
  let(:user) { create(:user) }
  let(:organization) { create(:organization) }
  let(:tag) { create(:tag, supported: true) }
  let(:article) { create(:article, tags: [tag.name], featured: true) }
  let(:reaction) { create(:reaction, user_id: user.id, reactable: article) }

  it "returns an article" do
    user.follow(tag)
    article2 = create(:article, tags: [tag.name], featured: true, boosted_additional_articles: true, organization_id: organization.id)
    suggested_id = described_class.new(tag.name, area: "additional_articles").suggest.id
    expect(suggested_id).to eq article2.id
  end
end
