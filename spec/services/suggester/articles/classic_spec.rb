require "rails_helper"

RSpec.describe Suggester::Articles::Classic do
  let(:user) { create(:user) }
  let(:tag) { create(:tag, supported: true) }
  let(:article) { create(:article, tags: [tag.name], featured: true) }
  let(:reaction) { create(:reaction, user_id: user.id, reactable_id: article.id) }

  it "returns an article" do
    create(:reaction, user_id: user.id, reactable_id: article.id)
    create(:reaction, user_id: user.id, reactable_id: article.id, category: "thinking")
    create(:reaction, user_id: user.id, reactable_id: article.id, category: "unicorn")
    expect(described_class.new(article).get.first.id).to eq article.id
  end

  it "does not return article if none exists with enough reactions" do
    user.follow(tag)
    expect(described_class.new(article).get).to eq []
  end

  it "returns single article if multiple qualify" do
    user.follow(tag)
    create(:reaction, user_id: user.id, reactable_id: article.id)
    create(:reaction, user_id: user.id, reactable_id: article.id, category: "thinking")
    create(:reaction, user_id: user.id, reactable_id: article.id, category: "unicorn")
    user2 = create(:user)
    article2 = create(:article, user_id: user2.id)
    create(:reaction, user_id: user2.id, reactable_id: article2.id)
    create(:reaction, user_id: user2.id, reactable_id: article2.id, category: "thinking")
    create(:reaction, user_id: user2.id, reactable_id: article2.id, category: "unicorn")
    expect(described_class.new(article).get.first&.id).to eq article.id
  end
end
