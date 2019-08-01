require "rails_helper"

RSpec.describe Follow, type: :model do
  let(:user) { create(:user) }
  let(:user_2) { create(:user) }

  describe "validations" do
    it { is_expected.to validate_inclusion_of(:subscription_status).in_array(%w[all_articles none]) }
  end

  it "follows user" do
    user.follow(user_2)
    expect(user.following?(user_2)).to eq(true)
  end

  context "when enqueuing jobs" do
    it "enqueues touch follower job on creation" do
      expect do
        described_class.create(follower: user, followable: user_2)
      end.to have_enqueued_job(Follows::TouchFollowerJob)
    end

    it "enqueues create channel job" do
      expect do
        described_class.create(follower: user, followable: user_2)
      end.to have_enqueued_job(Follows::CreateChatChannelJob)
    end

    it "enqueues send notification job" do
      expect do
        described_class.create(follower: user, followable: user_2)
      end.to have_enqueued_job(Follows::SendEmailNotificationJob)
    end
  end

  context "when creating and inline" do
    it "touches the follower user while creating" do
      timestamp = 1.day.ago
      user.update_columns(updated_at: timestamp, last_followed_at: timestamp)
      perform_enqueued_jobs do
        described_class.create!(follower: user, followable: user_2)
      end
      user.reload
      expect(user.updated_at).to be > timestamp
      expect(user.last_followed_at).to be > timestamp
    end

    it "doesn't create a channel when a followable is an org" do
      expect do
        perform_enqueued_jobs do
          described_class.create!(follower: user, followable: create(:organization))
        end
      end.not_to change(ChatChannel, :count)
    end

    it "doesn't create a chat channel when users don't follow mutually" do
      expect do
        perform_enqueued_jobs do
          described_class.create!(follower: user, followable: user_2)
        end
      end.not_to change(ChatChannel, :count)
    end

    it "creates a chat channel when users follow mutually" do
      described_class.create!(follower: user_2, followable: user)
      expect do
        perform_enqueued_jobs do
          described_class.create!(follower: user, followable: user_2)
        end
      end.to change(ChatChannel, :count).by(1)
    end

    it "sends an email notification" do
      user_2.update_column(:email_follower_notifications, true)
      expect do
        perform_enqueued_jobs do
          described_class.create!(follower: user, followable: user_2)
        end
      end.to change(EmailMessage, :count).by(1)
    end
  end
end
