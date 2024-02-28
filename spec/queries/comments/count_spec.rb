require "rails_helper"

RSpec.describe Comments::Count do
  let(:article) { create(:article) }
  let!(:comment) { create(:comment, commentable: article) }
  let!(:comment2) { create(:comment, commentable: article) }

  it "returns correct number with regular comments" do
    article.reload
    count = described_class.new(article).call
    expect(count).to eq(2)
  end

  it "returns correct number with children" do
    create(:comment, commentable: article, parent: comment2, score: 20)
    article.reload
    count = described_class.new(article).call
    expect(count).to eq(3)
  end

  it "doesn't include childless children" do
    create(:comment, commentable: article, parent: comment, score: -450)
    article.reload
    count = described_class.new(article).call
    expect(count).to eq(2)
  end

  it "includes ok children of a low-score comment (but not low-score children)" do
    comment.update_column(:score, -500)
    create(:comment, commentable: article, parent: comment, score: 10)
    create(:comment, commentable: article, parent: comment, score: -490)
    create(:comment, commentable: article, parent: comment2, score: 0)
    article.reload
    count = described_class.new(article).call
    expect(count).to eq(4)
  end

  it "includes children of a low-score comment" do
    child = create(:comment, commentable: article, parent: comment, score: -401)
    create(:comment, commentable: article, parent: child, score: 10)
    article.reload
    count = described_class.new(article).call
    expect(count).to eq(4)
  end

  it "includes a comment with low-score ancestors" do
    comment.update_column(:score, -500)
    child = create(:comment, commentable: article, parent: comment, score: -401)
    create(:comment, commentable: article, parent: child, score: 10)
    article.reload
    count = described_class.new(article).call
    expect(count).to eq(4)
  end
end
