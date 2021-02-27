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

  it "sets series" do
    attributes[:series] = "collection-slug"
    described_class.call(user, article.id, attributes)
    article.reload
    expect(article.collection).to be_a(Collection)
  end

  it "sets tags" do
    attributes[:tags] = %w[ruby productivity]
    described_class.call(user, article.id, attributes)
    article.reload
    expect(article.tags.pluck(:name).sort).to eq(%w[productivity ruby])
  end

  describe "notifications" do
    it "sends notifications when an article was published" do
      attributes[:published] = true
      sidekiq_assert_enqueued_with(job: Notifications::NotifiableActionWorker) do
        described_class.call(user, draft.id, attributes)
      end
    end

    it "doesn't send when an article was unpublished" do
      attributes[:published] = false
      sidekiq_assert_not_enqueued_with(job: Notifications::NotifiableActionWorker) do
        described_class.call(user, article.id, attributes)
      end
    end

    it "doesn't send when an article went from published to published" do
      attributes[:published] = true
      sidekiq_assert_not_enqueued_with(job: Notifications::NotifiableActionWorker) do
        described_class.call(user, article.id, attributes)
      end
    end
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
