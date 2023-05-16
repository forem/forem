require "rails_helper"

RSpec.describe Articles::Creator, type: :service do
  let(:user) { create(:user) }

  before do
    allow(FeatureFlag).to receive(:enabled?).with(:consistent_rendering, any_args).and_return(true)
    allow(SegmentedUserRefreshWorker).to receive(:perform_async)
  end

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

    it "creates a notification subscription" do
      expect do
        described_class.call(user, valid_attributes)
      end.to change(NotificationSubscription, :count).by(1)
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

    it "doesn't create a notification subscription" do
      expect do
        described_class.call(user, invalid_body_attributes)
      end.not_to change(NotificationSubscription, :count)
    end
  end

  context "when creating a published article" do
    let(:article_params) { attributes_for(:article, published: true) }

    it "refreshes user segments" do
      described_class.call(user, article_params)
      expect(SegmentedUserRefreshWorker).to have_received(:perform_async).with(user.id)
    end
  end

  context "when creating a not-yet-published article" do
    let(:article_params) { attributes_for(:article, published: false, published_at: 5.days.from_now) }

    it "does not refresh user segments" do
      described_class.call(user, article_params)
      expect(SegmentedUserRefreshWorker).not_to have_received(:perform_async)
    end
  end

  context "when creating a non-published article" do
    let(:article_params) { attributes_for(:article, published: false) }

    it "does not refresh user segments" do
      described_class.call(user, article_params)
      expect(SegmentedUserRefreshWorker).not_to have_received(:perform_async)
    end
  end
end
