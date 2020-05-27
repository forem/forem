require "rails_helper"

RSpec.describe Articles::Destroyer, type: :service do
  let(:article) { create(:article) }
  let(:event_dispatcher) { double }

  before do
    allow(event_dispatcher).to receive(:call)
  end

  xit "destroys an article" do
    described_class.call(article)
    expect(Article.find_by(id: article.id)).to be_nil
  end

  xit "schedules removing notifications if there are comments" do
    create(:comment, commentable: article)
    sidekiq_assert_enqueued_with(job: Notifications::RemoveAllWorker) do
      described_class.call(article)
    end
  end

  xit "calls events dispatcher" do
    described_class.call(article, event_dispatcher)
    expect(event_dispatcher).to have_received(:call).with("article_destroyed", article)
  end

  xit "doesn't call a dispatched when a draft is destroyed" do
    draft = create(:article, published: false)
    described_class.call(draft, event_dispatcher)
    expect(event_dispatcher).not_to have_received(:call)
  end
end
