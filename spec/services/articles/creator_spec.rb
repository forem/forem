require "rails_helper"

RSpec.describe Articles::Creator, type: :service do
  let(:user) { create(:user) }

  context "when valid attributes" do
    let(:valid_attributes) { attributes_for(:article) }

    it "creates an article" do
      expect do
        described_class.call(user, valid_attributes)
      end.to change(Article, :count).by(1)
    end

    it "returns a non decorated, persisted article" do
      article = described_class.call(user, valid_attributes)

      expect(article.decorated?).to be(false)
      expect(article).to be_persisted
    end

    it "schedules a job" do
      valid_attributes[:published] = true
      sidekiq_assert_enqueued_with(job: Notifications::NotifiableActionWorker) do
        described_class.call(user, valid_attributes)
      end
    end

    it "delegates to the Mentions::CreateAll service" do
      valid_attributes[:published] = true
      allow(Mentions::CreateAll).to receive(:call)
      article = described_class.call(user, valid_attributes)
      expect(Mentions::CreateAll).to have_received(:call).with(article)
    end

    it "creates a notification subscription" do
      expect do
        described_class.call(user, valid_attributes)
      end.to change(NotificationSubscription, :count).by(1)
    end

    it "calls an event dispatcher" do
      event_dispatcher = double
      allow(event_dispatcher).to receive(:call)
      article = described_class.call(user, valid_attributes, event_dispatcher)
      expect(event_dispatcher).to have_received(:call).with("article_created", article)
    end

    it "doesn't call an event dispatcher when an article is unpublished" do
      attributes = attributes_for(:article, published: false)
      event_dispatcher = double
      allow(event_dispatcher).to receive(:call)
      article = described_class.call(user, attributes, event_dispatcher)
      expect(event_dispatcher).not_to have_received(:call).with("article_created", article)
    end
  end

  context "when invalid attributes" do
    let(:invalid_body_attributes) { attributes_for(:article) }

    before do
      invalid_body_attributes[:title] = Faker::Book.title
      invalid_body_attributes[:body_markdown] = nil
    end

    it "doesn't create an invalid article" do
      expect do
        described_class.call(user, invalid_body_attributes)
      end.not_to change(Article, :count)
    end

    it "returns a non decorated, non persisted article" do
      article = described_class.call(user, invalid_body_attributes)

      expect(article.decorated?).to be(false)
      expect(article).not_to be_persisted
      expect(article.errors.size).to eq(1)
    end

    it "doesn't schedule a job" do
      sidekiq_assert_no_enqueued_jobs only: Notifications::NotifiableActionWorker do
        described_class.call(user, invalid_body_attributes)
      end
    end

    it "doesn't delegate to the Mentions::CreateAll service" do
      allow(Mentions::CreateAll).to receive(:call)
      article = described_class.call(user, invalid_body_attributes)
      expect(Mentions::CreateAll).not_to have_received(:call).with(article)
    end

    it "doesn't create a notification subscription" do
      expect do
        described_class.call(user, invalid_body_attributes)
      end.not_to change(NotificationSubscription, :count)
    end

    it "doesn't call an event dispatcher" do
      event_dispatcher = double
      allow(event_dispatcher).to receive(:call)
      described_class.call(user, invalid_body_attributes, event_dispatcher)
      expect(event_dispatcher).not_to have_received(:call)
    end
  end
end
