require "rails_helper"

RSpec.describe Articles::Updater, type: :service do
  let(:user) { create(:user) }
  let!(:article) { create(:article, user: user) }
  let(:attributes) { { body_markdown: "sample" } }
  let(:draft) { create(:article, user: user, published: false) }

  it "updates an article" do
    described_class.call(user, article.id, attributes)
    article.reload
    expect(article.body_markdown).to eq("sample")
  end

  describe "events dispatcher" do
    let(:event_dispatcher) { double }

    before do
      allow(event_dispatcher).to receive(:call)
    end

    it "calls the dispatcher" do
      described_class.call(user, article.id, attributes, event_dispatcher)
      expect(event_dispatcher).to have_received(:call).with("article_updated", article)
    end

    it "doesn't call the dispatcher when unpublished => unpublished" do
      described_class.call(user, draft.id, attributes, event_dispatcher)
      expect(event_dispatcher).not_to have_received(:call)
    end

    it "calls the dispatcher when unpublished => published" do
      attributes[:published] = true
      described_class.call(user, draft.id, attributes, event_dispatcher)
      expect(event_dispatcher).to have_received(:call).with("article_updated", draft)
    end

    it "calls the dispatcher when published => unpublished" do
      attributes[:published] = false
      described_class.call(user, article.id, attributes, event_dispatcher)
      expect(event_dispatcher).to have_received(:call).with("article_updated", article)
    end
  end
end
