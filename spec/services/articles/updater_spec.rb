require "rails_helper"

RSpec.describe Articles::Updater, type: :service do
  let(:user) { create(:user) }
  let!(:article) { create(:article, user: user) }
  let(:attributes) { { body_markdown: "sample" } }
  let(:draft) { create(:article, user: user, published: false) }

  it "updates an article" do
    described_class.call(user, article, attributes)
    article.reload
    expect(article.body_markdown).to eq("sample")
  end

  it "sets a collection" do
    attributes[:series] = "collection-slug"
    described_class.call(user, article, attributes)
    article.reload
    expect(article.collection).to be_a(Collection)
  end

  it "creates a collection for the user, not admin when updated by admin" do
    admin = create(:user, :super_admin)
    attributes[:series] = "new-slug"
    described_class.call(admin, article, attributes)
    expect(article.reload.collection.user).to eq(article.user)
  end

  it "sets tags" do
    attributes[:tags] = %w[ruby productivity]
    described_class.call(user, article, attributes)
    article.reload
    expect(article.tags.pluck(:name).sort).to eq(%w[productivity ruby])
  end

  describe "result" do
    it "returns success when saved" do
      result = described_class.call(user, article, attributes)
      expect(result.success).to be true
      expect(result.article).to be_a(ArticleDecorator)
    end

    it "returns not success when not saved" do
      invalid_attributes = { body_markdown: nil }
      result = described_class.call(user, article, invalid_attributes)
      expect(result.success).to be false
      expect(result.article.errors.any?).to be true
    end
  end

  describe "notifications" do
    it "sends notifications when an article was published" do
      attributes[:published] = true
      sidekiq_assert_enqueued_with(job: Notifications::NotifiableActionWorker) do
        described_class.call(user, draft, attributes)
      end
    end

    it "doesn't send when an article was unpublished" do
      attributes[:published] = false
      sidekiq_assert_not_enqueued_with(job: Notifications::NotifiableActionWorker) do
        described_class.call(user, article, attributes)
      end
    end

    it "doesn't send when an article went from published to published" do
      attributes[:published] = true
      sidekiq_assert_not_enqueued_with(job: Notifications::NotifiableActionWorker) do
        described_class.call(user, article, attributes)
      end
    end
  end

  describe "events dispatcher" do
    let(:event_dispatcher) { double }

    before do
      allow(event_dispatcher).to receive(:call)
    end

    it "calls the dispatcher" do
      described_class.call(user, article, attributes, event_dispatcher)
      expect(event_dispatcher).to have_received(:call).with("article_updated", article)
    end

    it "doesn't call the dispatcher when unpublished => unpublished" do
      described_class.call(user, draft, attributes, event_dispatcher)
      expect(event_dispatcher).not_to have_received(:call)
    end

    it "calls the dispatcher when unpublished => published" do
      attributes[:published] = true
      described_class.call(user, draft, attributes, event_dispatcher)
      expect(event_dispatcher).to have_received(:call).with("article_updated", draft)
    end

    it "calls the dispatcher when published => unpublished" do
      attributes[:published] = false
      described_class.call(user, article, attributes, event_dispatcher)
      expect(event_dispatcher).to have_received(:call).with("article_updated", article)
    end
  end
end
