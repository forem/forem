require "rails_helper"

RSpec.describe Articles::Updater do
  let(:user) { create(:user) }
  let!(:article) { create(:article, user: user) }
  let(:attributes) { { body_markdown: "sample" } }

  it "updates an article" do
    described_class.call(user, article.id, attributes)
    article.reload
    expect(article.body_markdown).to eq("sample")
  end

  it "calls events dispatcher" do
    event_dispatcher = double
    allow(event_dispatcher).to receive(:call)
    described_class.call(user, article.id, attributes, event_dispatcher)
    expect(event_dispatcher).to have_received(:call).with("article_updated", article)
  end
end
