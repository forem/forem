require "rails_helper"

RSpec.describe Articles::Creator do
  let(:user) { create(:user) }

  context "when valid attributes" do
    let(:valid_attributes) { attributes_for(:article) }

    it "creates an article" do
      expect do
        described_class.call(user, valid_attributes)
      end.to change(Article, :count).by(1)
    end

    it "returns an article" do
      article = described_class.call(user, valid_attributes)
      expect(article).to be_kind_of(Article)
      expect(article).to be_persisted
    end

    it "schedules a job" do
      valid_attributes[:published] = true
      expect do
        described_class.call(user, valid_attributes)
      end.to have_enqueued_job(Notifications::NotifiableActionJob).once
    end

    it "creates a notification subscription" do
      expect do
        described_class.call(user, valid_attributes)
      end.to change(NotificationSubscription, :count).by(1)
    end
  end

  context "when valid attributes" do
    let(:invalid_attributes) { attributes_for(:article) }

    before do
      invalid_attributes[:body_markdown] = nil
    end

    it "doesn't create an invalid article" do
      expect do
        described_class.call(user, invalid_attributes)
      end.not_to change(Article, :count)
    end

    it "returns an unsaved article" do
      article = described_class.call(user, invalid_attributes)
      expect(article).to be_kind_of(Article)
      expect(article).not_to be_persisted
      expect(article.errors.size).to eq(1)
    end

    it "doesn't schedule a job" do
      expect do
        described_class.call(user, invalid_attributes)
      end.not_to have_enqueued_job(1).on_queue(:send_notifiable_action_notification)
    end

    it "doesn't create a notification subscription" do
      expect do
        described_class.call(user, invalid_attributes)
      end.not_to change(NotificationSubscription, :count)
    end
  end
end
