require "rails_helper"

RSpec.describe Follow, type: :model do
  let(:user) { create(:user) }
  let(:user_2) { create(:user) }

  it "follows user" do
    user.follow(user_2)
    expect(user.following?(user_2)).to eq(true)
  end

  context "when enqueuing jobs" do
    before { ActiveJob::Base.queue_adapter = :test }

    it "enqueues touch follower job on creation" do
      expect do
        Follow.create(follower: user, followable: user_2)
      end.to have_enqueued_job(Follows::TouchFollowerJob)
    end

    it "enqueues create channel job" do
      expect do
        Follow.create(follower: user, followable: user_2)
      end.to have_enqueued_job(Follows::CreateChatChannelJob)
    end

    it "enqueues send notification job" do
      expect do
        Follow.create(follower: user, followable: user_2)
      end.to have_enqueued_job(Follows::SendEmailNotificationJob)
    end
  end

  context "when creating and inline" do
    before { ActiveJob::Base.queue_adapter = :inline }

    it "touches the follower user while creating" do
      user.update_columns(updated_at: Time.now - 1.day, last_followed_at: Time.now - 1.day)
      now = Time.now
      Follow.create!(follower: user, followable: user_2)
      user.reload
      expect(user.updated_at).to be >= now
      expect(user.last_followed_at).to be >= now
    end

    it "doesn't create a channel when a followable is an org" do
      expect do
        Follow.create!(follower: user, followable: create(:organization))
      end.not_to change(ChatChannel, :count)
    end

    it "doesn't create a chat channel when users don't follow mutually" do
      expect do
        Follow.create!(follower: user, followable: user_2)
      end.not_to change(ChatChannel, :count)
    end

    it "creates a chat channel when users follow mutually" do
      Follow.create!(follower: user_2, followable: user)
      expect do
        Follow.create!(follower: user, followable: user_2)
      end.to change(ChatChannel, :count).by(1)
    end

    it "sends an email notification" do
      user_2.update_column(:email_follower_notifications, true)
      expect do
        run_background_jobs_immediately do
          Follow.create!(follower: user, followable: user_2)
        end
      end.to change(EmailMessage, :count).by(1)
    end
  end
end
