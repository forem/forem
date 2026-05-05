require "rails_helper"

RSpec.describe Comments::CalculateScore, type: :service do
  let(:article) { create(:article) }
  let(:comment) { create(:comment, commentable: article) }
  let(:user) { instance_double(User, spam?: false) }

  before do
    allow(BlackBox).to receive(:comment_quality_score).and_return(7)
  end

  it "updates the score" do
    described_class.call(comment)
    comment.reload
    expect(comment.score).to be(7)
  end

  context "when adding spam role" do
    before do
      comment.user.add_role(:spam)
      comment.update_column(:updated_at, 1.day.ago)
    end

    it "updates the score and updated_at with a penalty if the user is a spammer", :aggregate_failures do
      described_class.call(comment)
      comment.reload
      expect(comment.score).to be(-493)
      expect(comment.updated_at).to be_within(1.minute).of(Time.current)
    end

    it "updates article displayed comments count" do
      other_comment = create(:comment, commentable: article)
      create(:comment, commentable: article, parent: other_comment)
      described_class.call(comment)
      article.reload
      expect(article.comments_count).to eq(3)
      expect(article.displayed_comments_count).to eq(2)
    end
  end

  describe "ArticleActivity enqueue on score transitions" do
    it "enqueues a create event when score crosses from 0 to positive" do
      comment.update_columns(score: 0)
      allow(Articles::UpdateArticleActivityWorker).to receive(:perform_async)
      described_class.call(comment)
      expect(Articles::UpdateArticleActivityWorker)
        .to have_received(:perform_async)
        .with(article.id, "comment", "create", hash_including("iso"))
    end

    it "enqueues a destroy event when score drops from positive to non-positive" do
      comment.update_columns(score: 5)
      allow(BlackBox).to receive(:comment_quality_score).and_return(0)
      allow(Articles::UpdateArticleActivityWorker).to receive(:perform_async)
      described_class.call(comment)
      expect(Articles::UpdateArticleActivityWorker)
        .to have_received(:perform_async)
        .with(article.id, "comment", "destroy", hash_including("iso"))
    end

    it "does not enqueue when the positive/non-positive sign does not change" do
      comment.update_columns(score: 3)
      allow(Articles::UpdateArticleActivityWorker).to receive(:perform_async)
      described_class.call(comment)
      expect(Articles::UpdateArticleActivityWorker).not_to have_received(:perform_async)
    end
  end
end
