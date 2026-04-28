require "rails_helper"

RSpec.describe Articles::Destroyer, type: :service do
  let(:article) { create(:article) }
  let(:event_dispatcher) { double }

  it "destroys an article" do
    described_class.call(article)
    expect(Article.find_by(id: article.id)).to be_nil
  end

  it "schedules removing notifications if there are comments" do
    create(:comment, commentable: article)
    sidekiq_assert_enqueued_with(job: Notifications::RemoveAllWorker) do
      described_class.call(article)
    end
  end

  it "busts the author's profile cache so stale pinned-article cards are evicted" do
    user = article.user
    allow(EdgeCache::BustUser).to receive(:call)
    described_class.call(article)
    expect(EdgeCache::BustUser).to have_received(:call).with(user)
  end
end
