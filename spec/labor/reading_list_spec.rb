require 'rails_helper'

RSpec.describe ReadingList do
  let(:user) { create(:user) }
  let(:article) { create(:article) }
  let(:article2) { create(:article) }
  let(:article3) { create(:article) }
  it "returns count of articles if they've been reacted to" do
    Reaction.create!(
        user_id: user.id,
        reactable_id: article.id,
        reactable_type: "Article",
        category: "readinglist",
      )
    Reaction.create!(
        user_id: user.id,
        reactable_id: article2.id,
        reactable_type: "Article",
        category: "readinglist",
      )
    expect(ReadingList.new(user).count).to eq(2)
  end

  it "returns an article if it's been reacted to" do
    Reaction.create!(
        user_id: user.id,
        reactable_id: article.id,
        reactable_type: "Article",
        category: "readinglist",
      )
    Reaction.create!(
        user_id: user.id,
        reactable_id: article2.id,
        reactable_type: "Article",
        category: "readinglist",
      )
    expect(ReadingList.new(user).get.first.id).to eq(article2.id)
  end

    it "returns an article if it's been reacted to" do
    Reaction.create!(
        user_id: user.id,
        reactable_id: article.id,
        reactable_type: "Article",
        category: "readinglist",
      )
    Reaction.create!(
        user_id: user.id,
        reactable_id: article2.id,
        reactable_type: "Article",
        category: "readinglist",
      )
    expect(ReadingList.new(user).cached_ids_of_articles).to eq([article2.id,article.id])
  end


  it "returns an empty count if no reacted article" do
    expect(ReadingList.new(user).count).to eq(0)
  end

end