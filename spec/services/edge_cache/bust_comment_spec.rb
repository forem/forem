require "rails_helper"

RSpec.describe EdgeCache::BustComment, type: :service do
  let(:commentable) { create(:article) }
  let(:buster) { instance_double(EdgeCache::Buster) }

  before do
    allow(EdgeCache::Buster).to receive(:new).and_return(buster)
    allow(buster).to receive(:bust)
    allow(described_class).to receive(:bust_article_comment).with(buster, commentable)
  end

  it "busts the cache" do
    described_class.call(commentable)
    expect(buster).to have_received(:bust).with("#{commentable.path}/comments/*").once
  end

  context "when commentable is an article" do
    it "bust article comments" do
      described_class.call(commentable)
      expect(described_class).to have_received(:bust_article_comment).with(buster, commentable)
    end
  end

  context "when commentable is not an article" do
    it "doesn't bust article comments" do
      podcast_episode = create(:podcast_episode)
      described_class.call(podcast_episode)
      expect(described_class).not_to have_received(:bust_article_comment).with(buster, commentable)
    end
  end
end
