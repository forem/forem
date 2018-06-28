require 'rails_helper'

RSpec.describe Suggester::Articles::Boosted do
  let(:user) { create(:user) }
  let(:organization) { create(:organization) }
  let(:tag) { create(:tag, supported: true) }
  let(:article) { create(:article, tags: [tag.name], featured: true) }
  let(:article_3) { create(:article, tags: [tag.name], featured: true, boosted_additional_articles: true, organization_id: organization.id) }
  let(:reaction) { create(:reaction, user_id: user.id, reactable_id: article.id) }

  it "returns an article" do
    user.follow(tag)
    article_2 = create(:article, tags: [tag.name], featured: true, boosted_additional_articles: true, organization_id: organization.id)
    expect(described_class.new(user, article, {area: "additional_articles"}).suggest.id).to eq article_2.id
  end
end