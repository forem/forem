require "rails_helper"

RSpec.describe EdgeCache::BustComment, type: :service do
  let(:commentable) { create(:article) }
  let(:comment) { create(:comment, commentable: commentable) }

  before do
    allow(EdgeCache::PurgeByKey).to receive(:call)
    allow(described_class).to receive(:bust_article_comment).with(commentable)
  end

  it "busts the cache" do
    described_class.call(commentable)
    expect(EdgeCache::PurgeByKey).to have_received(:call).with(
      [commentable.record_key],
      fallback_paths: [commentable.path],
    )
  end

  it "busts the cache for a comment" do
    described_class.call(comment)
    expect(EdgeCache::PurgeByKey).to have_received(:call).with(
      [commentable.record_key, comment.record_key],
      fallback_paths: [commentable.path, comment.path],
    )
  end

  context "when commentable is an article" do
    it "bust article comments" do
      described_class.call(commentable)
      expect(described_class).to have_received(:bust_article_comment).with(commentable)
    end
  end

  context "when commentable is not an article" do
    it "doesn't bust article comments" do
      podcast_episode = create(:podcast_episode)
      described_class.call(podcast_episode)
      expect(described_class).not_to have_received(:bust_article_comment).with(podcast_episode)
    end
  end
end
