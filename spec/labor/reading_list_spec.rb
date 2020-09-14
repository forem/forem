require "rails_helper"

RSpec.describe ReadingList, type: :labor do
  let(:user) { create(:user) }
  let(:article) { create(:article) }
  let(:article2) { create(:article) }
  let(:article3) { create(:article) }

  def create_reaction(user, article)
    Reaction.create!(
      user_id: user.id,
      reactable_id: article.id,
      reactable_type: "Article",
      category: "readinglist",
    )
  end

  it "returns cached ids of articles that have been reacted to" do
    create_reaction(user, article)
    create_reaction(user, article2)

    expect(described_class.new(user).cached_ids_of_articles).to eq([article2.id, article.id])
  end
end
