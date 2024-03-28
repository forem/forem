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

  context "with recalculate option" do
    # displayed comments count = 4
    # comments count = 5
    before do
      comment.update_column(:score, -500)
      create(:comment, commentable: article, parent: comment, score: 10)
      create(:comment, commentable: article, parent: comment, score: -490)
      create(:comment, commentable: article, parent: comment2, score: 0)
      article.reload
    end

    it "returns displayed_comments_count if it exists + no recalculate" do
      article.update_column(:displayed_comments_count, 3)
      cnt = described_class.call(article, recalculate: false)
      expect(cnt).to eq(3)
    end

    it "recalculates if recalculate is passed", :aggregate_failures do
      article.update_column(:displayed_comments_count, 3)
      cnt = described_class.call(article, recalculate: true)
      expect(cnt).to eq(4)
      article.reload
      expect(article.displayed_comments_count).to eq(4)
    end

    it "recalculates if no recalculate and no displayed_comments_count", :aggregate_failures do
      cnt = described_class.call(article, recalculate: false)
      expect(cnt).to eq(4)
      article.reload
      expect(article.displayed_comments_count).to eq(4)
    end
  end
end
