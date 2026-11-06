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

  it "excludes childless soft-deleted comments" do
    comment.update!(deleted: true)
    article.reload
    count = described_class.new(article).call
    expect(count).to eq(1) # Only comment2 is displayed
  end

  it "includes soft-deleted parent comments with active replies" do
    create(:comment, commentable: article, parent: comment, score: 10)
    comment.update!(deleted: true)
    article.reload
    count = described_class.new(article).call
    expect(count).to eq(3) # comment, active reply, and comment2 are displayed
  end

  it "only treats an exact last ancestry segment as a reply to a hidden comment" do
    comment.update_column(:score, -500)
    other_parent = create(:comment, commentable: article)
    reply = create(:comment, commentable: article, parent: other_parent)
    # Ancestries whose last segment merely contains the hidden comment's id are not its replies
    reply.update_column(:ancestry, "#{comment.id}/#{other_parent.id}#{comment.id}")
    article.reload
    expect(described_class.new(article).call).to eq(3)
  end

  it "matches the correlated LIKE count across a randomized comment tree" do
    comment.update_column(:score, -500)
    comments = [comment, comment2]
    25.times do
      parent = [nil, *comments].sample
      comments << create(:comment, commentable: article, parent: parent, score: [-500, -401, 0, 10].sample,
                                   deleted: [true, false, false].sample)
    end
    create(:comment, commentable: create(:article), parent: nil).update_column(:ancestry, comment.id.to_s)
    legacy_hidden = Comment.count_by_sql(Comment.sanitize_sql([<<~SQL.squish, Comment::HIDE_THRESHOLD, article.id]))
      SELECT COUNT(id) FROM comments c1 WHERE (score < ? OR deleted = TRUE) AND commentable_id = ?
      AND commentable_type = 'Article' AND NOT EXISTS (SELECT 1 FROM comments c2
      WHERE c2.commentable_id = c1.commentable_id AND c2.commentable_type = c1.commentable_type
      AND (c2.ancestry LIKE CONCAT('%/', c1.id::varchar(255)) OR c2.ancestry = c1.id::varchar(255)))
    SQL
    article.reload
    expect(described_class.call(article, recalculate: true)).to eq(article.comments.count - legacy_hidden)
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

    it "does not recalculate or write to database when displayed_comments_count is 0" do
      article.update_column(:displayed_comments_count, 0)
      allow(article).to receive(:update_column).and_call_original
      cnt = described_class.call(article, recalculate: false)
      expect(cnt).to eq(0)
      expect(article).not_to have_received(:update_column)
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

    it "computes the count in a single comments SELECT query and skips update_column when unchanged",
       :aggregate_failures do
      article.update_column(:displayed_comments_count, 4)
      allow(article).to receive(:update_column).and_call_original

      comment_selects = []
      callback = lambda do |*, payload|
        sql = payload[:sql].to_s
        comment_selects << sql if !payload[:cached] && sql.match?(/\ASELECT .* FROM "?comments"?/i)
      end

      cnt = ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
        described_class.call(article, recalculate: true)
      end

      expect(cnt).to eq(4)
      expect(comment_selects.size).to eq(1)
      expect(article).not_to have_received(:update_column)
    end
  end
end
