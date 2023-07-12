require "rails_helper"

RSpec.describe Notifications::BustCaches, type: :service do
  subject(:buster) { described_class.new(user: user) }

  let(:article) { create(:article) }
  let!(:last_reaction) { create(:reaction, reactable: article, user: user) }
  let(:comment) { create(:comment) }
  let(:user) { create(:user) }

  it "knows the id of the last user reaction" do
    expect(buster.last_user_reaction).to eq(last_reaction.id)
  end

  it "knows the effected article id" do
    buster = described_class.new(user: user, notifiable: article)
    expect(buster.effected_article_id).to eq(article.id)

    buster = described_class.new(user: user, notifiable: comment)
    expect(buster.effected_article_id).to eq(comment.commentable_id)
  end

  context "when notifiable is an article" do
    before do
      allow(Rails.cache).to receive(:delete_matched)

      described_class.call(user: user, notifiable: article)
    end

    it "deletes the cache for article and comment notifications" do
      expect(Rails.cache).to have_received(:delete_matched)
        .with("*activity-published-article-reactions-#{last_reaction.id}-*-#{article.id}")

      expect(Rails.cache).to have_received(:delete_matched)
        .with("*comment-box-#{last_reaction.id}-*")
    end
  end

  context "when notifiable is a comment" do
    before do
      allow(Rails.cache).to receive(:delete_matched)

      described_class.call(user: user, notifiable: comment)
    end

    it "deletes the cache for article and comment notifications" do
      expect(Rails.cache).to have_received(:delete_matched)
        .with("*activity-published-article-reactions-#{last_reaction.id}-*-#{comment.commentable_id}")

      expect(Rails.cache).to have_received(:delete_matched)
        .with("*comment-box-#{last_reaction.id}-*")
    end
  end

  context "when given a notifiable_id and notifiable_type" do
    it "can find a valid notifiable" do
      buster = described_class.new(user: user,
                                   notifiable_id: article.id,
                                   notifiable_type: "Article")
      expect(buster.notifiable).to eq(article)

      buster = described_class.new(user: user,
                                   notifiable_id: comment.id,
                                   notifiable_type: "Comment")
      expect(buster.notifiable).to eq(comment)
    end

    it "raises with an invalid type" do
      buster = described_class.new(user: user,
                                   notifiable_id: article.id,
                                   notifiable_type: "Monkey")
      expect { buster.notifiable }.to raise_error(KeyError)
    end

    it "raises with an invalid id" do
      buster = described_class.new(user: user,
                                   notifiable_id: "1234567",
                                   notifiable_type: "Article")
      expect { buster.notifiable }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
