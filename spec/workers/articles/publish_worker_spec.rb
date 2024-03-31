require "rails_helper"

RSpec.describe Articles::PublishWorker, type: :worker do
  let(:worker) { subject }
  let!(:article) { create(:article, published: true) }

  include_examples "#enqueues_on_correct_queue", "medium_priority"

  it "calls Slack::Messengers::ArticlePublished to send slack notifications" do
    allow(Slack::Messengers::ArticlePublished).to receive(:call)
    worker.perform
    expect(Slack::Messengers::ArticlePublished).to have_received(:call).with(article: article)
  end

  it "sends notifications to mentioned users and followers" do
    allow(Notification).to receive(:send_to_mentioned_users_and_followers)
    worker.perform
    expect(Notification).to have_received(:send_to_mentioned_users_and_followers).with(article)
  end

  it "schedules Notifications::NotifiableActionWorker" do
    args = [article.id, "Article", "Published"]
    sidekiq_assert_enqueued_with(job: Notifications::NotifiableActionWorker, args: args) do
      worker.perform
    end
  end

  it "doesn't send notifications for an old article" do
    old_article = create(:article, :past, published: true, past_published_at: 1.year.ago)
    allow(Notification).to receive(:send_to_mentioned_users_and_followers)
    worker.perform
    expect(Notification).not_to have_received(:send_to_mentioned_users_and_followers).with(old_article)
  end

  it "doesn't send notifications for a scheduled article" do
    scheduled_article = create(:article, published: true, published_at: 1.day.from_now)
    allow(Notification).to receive(:send_to_mentioned_users_and_followers)
    worker.perform
    expect(Notification).not_to have_received(:send_to_mentioned_users_and_followers).with(scheduled_article)
  end

  context "with 2 articles" do
    let!(:article2) { create(:article, published: true) }

    it "schedules Notifications::NotifiableActionWorker twice for 2 articles" do
      sidekiq_assert_enqueued_jobs(2, only: Notifications::NotifiableActionWorker) do
        worker.perform
      end
    end

    it "sends notifications to mentioned users and followers for 2 articles" do
      allow(Notification).to receive(:send_to_mentioned_users_and_followers)
      worker.perform
      expect(Notification).to have_received(:send_to_mentioned_users_and_followers).with(article2)
    end
  end

  describe "creating notifications" do
    let!(:user2) { create(:user) }
    let(:article2) { create(:article, published: true, user: user2) }

    before do
      user2.follow(article.user)
    end

    it "creates a notification eventually" do
      expect do
        sidekiq_perform_enqueued_jobs(only: Notifications::NotifiableActionWorker) do
          worker.perform
        end
      end.to change(Notification, :count).by(1)
    end

    it "creates a context notification as well" do
      expect do
        sidekiq_perform_enqueued_jobs(only: Notifications::NotifiableActionWorker) do
          worker.perform
        end
      end.to change(ContextNotification, :count).by(1)
    end

    it "creates a notification for each article" do
      article2
      article.user.follow(article2.user)
      expect do
        sidekiq_perform_enqueued_jobs(only: Notifications::NotifiableActionWorker) do
          worker.perform
        end
      end.to change(Notification, :count).by(2)
    end

    it "creates a ContextNotification for each article" do
      article2
      article.user.follow(article2.user)
      expect do
        sidekiq_perform_enqueued_jobs(only: Notifications::NotifiableActionWorker) do
          worker.perform
        end
      end.to change(ContextNotification, :count).by(2)
    end
  end
end
