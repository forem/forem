require "rails_helper"

RSpec.describe Articles::Destroyer do
  let(:article) { create(:article) }

  it "destroys an article" do
    described_class.call(article)
    expect(Article.find_by(id: article.id)).to be_nil
  end

  it "schedules removing notifications" do
    expect do
      described_class.call(article)
    end.to have_enqueued_job(Notifications::RemoveAllJob).once
  end

  it "calls events dispatcher" do
    event_dispatcher = double
    allow(event_dispatcher).to receive(:call)
    described_class.call(article, event_dispatcher)
    expect(event_dispatcher).to have_received(:call).with("article_destroyed", article)
  end
end
