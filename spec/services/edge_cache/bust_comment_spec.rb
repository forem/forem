require "rails_helper"

RSpec.describe EdgeCache::BustComment, type: :service do
  let(:commentable) { create(:article) }
  let(:cache_bust) { instance_double(EdgeCache::Bust) }

  before do
    allow(EdgeCache::Bust).to receive(:new).and_return(cache_bust)
    allow(cache_bust).to receive(:call)
    allow(described_class).to receive(:bust_article_comment).with(cache_bust, commentable)
  end

  it "busts the cache" do
    described_class.call(commentable)
    expect(cache_bust).to have_received(:call).with("#{commentable.path}/comments/*").once
  end

  context "when commentable is an article" do
    it "bust article comments" do
      described_class.call(commentable)
      expect(described_class).to have_received(:bust_article_comment).with(cache_bust, commentable)
    end
  end

  context "when commentable is not an article" do
    it "doesn't bust article comments" do
      podcast_episode = create(:podcast_episode)
      described_class.call(podcast_episode)
      expect(described_class).not_to have_received(:bust_article_comment).with(cache_bust, commentable)
    end
  end
end
