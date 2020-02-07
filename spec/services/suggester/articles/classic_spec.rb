require "rails_helper"

RSpec.describe Suggester::Articles::Classic, type: :service do
  let(:user) { create(:user) }
  let(:tag) { create(:tag, supported: true) }
  let(:article) { create(:article, tags: [tag.name], featured: true) }
  let(:reaction) { create(:reaction, user_id: user.id, reactable: article) }

  it "returns an article" do
    create(:reaction, user_id: user.id, reactable: article)
    create(:reaction, user_id: user.id, reactable: article, category: "thinking")
    create(:reaction, user_id: user.id, reactable: article, category: "unicorn")
    expect(described_class.new(article).get.first.id).to eq article.id
  end

  it "does not return article if none exists with enough reactions" do
    user.follow(tag)
    expect(described_class.new(article).get).to eq []
  end

  it "returns single article if multiple qualify" do
    user.follow(tag)
    create(:reaction, user_id: user.id, reactable: article)
    create(:reaction, user_id: user.id, reactable: article, category: "thinking")
    create(:reaction, user_id: user.id, reactable: article, category: "unicorn")
    user2 = create(:user)
    article2 = create(:article, user_id: user2.id)
    create(:reaction, user_id: user2.id, reactable: article2)
    create(:reaction, user_id: user2.id, reactable: article2, category: "thinking")
    create(:reaction, user_id: user2.id, reactable: article2, category: "unicorn")
    expect(described_class.new(article).get.first&.id).to eq article.id
  end
end
