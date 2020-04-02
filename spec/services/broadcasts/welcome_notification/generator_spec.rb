require "rails_helper"

RSpec.describe Broadcasts::WelcomeNotification::Generator, type: :service do
  let(:mascot_account)             { create(:user) }
  let!(:welcome_thread)            { create(:article, user: mascot_account, published: true, tags: "welcome") }
  let!(:welcome_broadcast)         { create(:welcome_broadcast) }

  before do
    allow(Notification).to receive(:send_welcome_notification).and_call_original
    allow(User).to receive(:mascot_account).and_return(mascot_account)
    SiteConfig.staff_user_id = mascot_account.id
  end

  after do
    # SiteConfig.clear_cache should work here but for some reason it isn't
    SiteConfig.staff_user_id = 1
  end

  it "requires a valid user id" do
    expect { described_class.call(1) }.to raise_error(ActiveRecord::RecordNotFound)
  end

  describe "::call" do
    it "does not send a notification to an unsubscribed user" do
      user = create(:user, :with_identity, identities: ["github"], created_at: 1.week.ago, welcome_notifications: false)
      expect do
        sidekiq_perform_enqueued_jobs { described_class.call(user.id) }
      end.to not_change(user.notifications, :count)
    end

    it "sends only 1 notification at a time" do
      user = create(:user, :with_identity, identities: ["github"], created_at: 1.week.ago)
      expect do
        sidekiq_perform_enqueued_jobs { described_class.call(user.id) }
      end.to change(user.notifications, :count).by(1)
    end
  end

  describe "#send_welcome_notification" do
    let(:user) { create(:user, created_at: 4.hours.ago) }

    it "does not send a notification to a newly-created user" do
      user.update!(created_at: Time.zone.now)
      sidekiq_perform_enqueued_jobs { described_class.new(user.id).send(:send_welcome_notification) }
      expect(user.notifications.count).to eq(0)
    end

    it "generates the correct broadcast type and sends the notification to the user" do
      sidekiq_perform_enqueued_jobs { described_class.new(user.id).send(:send_welcome_notification) }
      expect(user.notifications.first.notifiable).to eq(welcome_broadcast)
    end

    it "does not send to a user who has commented in a welcome thread" do
      create(:comment, commentable: welcome_thread, commentable_type: "Article", user: user)
      expect do
        sidekiq_perform_enqueued_jobs { described_class.new(user.id).send(:send_welcome_notification) }
      end.not_to change(user.notifications, :count)
    end

    it "does not send duplicate notifications" do
      2.times { sidekiq_perform_enqueued_jobs { described_class.new(user.id).send(:send_welcome_notification) } }
      expect(user.notifications.count).to eq(1)
    end
  end

  describe "#send_authentication_notification" do
    let!(:twitter_connect_broadcast) { create(:twitter_connect_broadcast) }
    let!(:github_connect_broadcast)  { create(:github_connect_broadcast) }

    it "does not send notification if user is created less than a day ago" do
      user = create(:user, :with_identity, identities: ["github"])
      sidekiq_perform_enqueued_jobs { described_class.new(user.id).send(:send_authentication_notification) }
      expect(Notification).not_to have_received(:send_welcome_notification)
    end

    it "generates and sends the appropriate broadcast (twitter)" do
      user = create(:user, :with_identity, identities: ["github"], created_at: 1.day.ago)
      sidekiq_perform_enqueued_jobs { described_class.new(user.id).send(:send_authentication_notification) }
      expect(user.notifications.first.notifiable).to eq(twitter_connect_broadcast)
    end

    it "generates and sends the appropriate broadcast (github)" do
      user = create(:user, :with_identity, identities: ["twitter"], created_at: 1.day.ago)
      sidekiq_perform_enqueued_jobs { described_class.new(user.id).send(:send_authentication_notification) }
      expect(user.notifications.first.notifiable).to eq(github_connect_broadcast)
    end

    it "does not send notification if user is authenticated with both services" do
      user = create(:user, :with_identity, identities: %w[twitter github], created_at: 1.day.ago)
      sidekiq_perform_enqueued_jobs { described_class.new(user.id).send(:send_authentication_notification) }
      expect(Notification).not_to have_received(:send_welcome_notification).with(user.id, github_connect_broadcast.id)
    end

    it "does not send duplicate notifications (github)" do
      user = create(:user, :with_identity, identities: ["twitter"], created_at: 1.day.ago)
      2.times do
        sidekiq_perform_enqueued_jobs { described_class.new(user.id).send(:send_authentication_notification) }
      end
      expect(user.notifications.count).to eq(1)
    end

    it "does not send duplicate notifications (twitter)" do
      user = create(:user, :with_identity, identities: ["github"], created_at: 1.day.ago)
      2.times do
        sidekiq_perform_enqueued_jobs { described_class.new(user.id).send(:send_authentication_notification) }
      end
      expect(user.notifications.count).to eq(1)
    end
  end

  describe "#send_feed_customization_notification" do
    let!(:user) { create(:user, :with_identity, identities: %w[twitter github], created_at: 3.days.ago) }
    let!(:customize_feed_broadcast)  { create(:customize_feed_broadcast) }

    it "does not send a notification to a newly-created user" do
      user.update!(created_at: Time.zone.now)
      sidekiq_perform_enqueued_jobs { described_class.new(user.id).send(:send_feed_customization_notification) }
      expect(Notification).not_to have_received(:send_welcome_notification)
    end

    it "does not send a notification to a user that is following 2 tags" do
      2.times { user.follow(create(:tag)) }
      sidekiq_perform_enqueued_jobs { described_class.new(user.id).send(:send_feed_customization_notification) }
      expect(Notification).not_to have_received(:send_welcome_notification)
    end

    it "sends a notification to a user with 0 tag follows" do
      sidekiq_perform_enqueued_jobs { described_class.new(user.id).send(:send_feed_customization_notification) }
      expect(user.notifications.count).to eq(1)
      expect(user.notifications.first.notifiable).to eq(customize_feed_broadcast)
    end

    it "does not send duplicate notifications" do
      2.times do
        sidekiq_perform_enqueued_jobs { described_class.new(user.id).send(:send_feed_customization_notification) }
      end
      expect(user.notifications.count).to eq(1)
    end
  end

  describe "#send_ux_customization_notification" do
    let!(:user) { create(:user, :with_identity, identities: %w[twitter github], created_at: 5.days.ago) }
    let!(:customize_ux_broadcast) { create(:customize_ux_broadcast) }

    it "does not send a notification to a newly-created user" do
      user.update!(created_at: Time.zone.now)
      sidekiq_perform_enqueued_jobs { described_class.new(user.id).send(:send_ux_customization_notification) }
      expect(Notification).not_to have_received(:send_welcome_notification)
    end

    it "generates the correct broadcast type and sends the notification to the user" do
      sidekiq_perform_enqueued_jobs { described_class.new(user.id).send(:send_ux_customization_notification) }
      expect(user.notifications.count).to eq(1)
      expect(user.notifications.first.notifiable).to eq(customize_ux_broadcast)
    end

    it "does not send duplicate notifications" do
      2.times do
        sidekiq_perform_enqueued_jobs { described_class.new(user.id).send(:send_ux_customization_notification) }
      end
      expect(user.notifications.count).to eq(1)
    end
  end

  describe "#send_discuss_and_ask_notification" do
    let!(:user) { create(:user, :with_identity, identities: %w[twitter github], created_at: 6.days.ago) }
    let!(:ask_question_broadcast) { create(:ask_question_broadcast) }
    let!(:start_discussion_broadcast) { create(:start_discussion_broadcast) }
    let!(:discuss_and_ask_broadcast) { create(:discuss_and_ask_broadcast) }

    context "with a user who has asked a question" do
      it "generates the correct broadcast type and sends the notification to the user" do
        create(:article, tags: "explainlikeimfive", user: user)

        sidekiq_perform_enqueued_jobs { described_class.new(user.id).send(:send_discuss_and_ask_notification) }
        expect(user.notifications.count).to eq(1)
        expect(user.notifications.first.notifiable).to eq(start_discussion_broadcast)
      end
    end

    context "with a user who has started a discussion" do
      it "generates the correct broadcast type and sends the notification to the user" do
        create(:article, tags: "discuss", user: user)

        sidekiq_perform_enqueued_jobs { described_class.new(user.id).send(:send_discuss_and_ask_notification) }
        expect(user.notifications.count).to eq(1)
        expect(user.notifications.first.notifiable).to eq(ask_question_broadcast)
      end
    end

    context "with a user who has neither asked a question and started a discussion" do
      it "generates the correct broadcast type and sends the notification to the user" do
        sidekiq_perform_enqueued_jobs { described_class.new(user.id).send(:send_discuss_and_ask_notification) }
        expect(user.notifications.count).to eq(1)
        expect(user.notifications.first.notifiable).to eq(discuss_and_ask_broadcast)
      end
    end

    context "with a user who has asked a question and started a discussion" do
      it "does not send a notification" do
        create(:article, tags: "discuss", user: user)
        create(:article, tags: "explainlikeimfive", user: user)

        sidekiq_perform_enqueued_jobs { described_class.new(user.id).send(:send_discuss_and_ask_notification) }
        expect(Notification).not_to have_received(:send_welcome_notification)
      end
    end

    it "does not send a notification to a newly-created user" do
      user.update!(created_at: Time.zone.now)
      sidekiq_perform_enqueued_jobs { described_class.new(user.id).send(:send_discuss_and_ask_notification) }
      expect(Notification).not_to have_received(:send_welcome_notification)
    end

    it "does not send duplicate notifications" do
      2.times do
        sidekiq_perform_enqueued_jobs { described_class.new(user.id).send(:send_discuss_and_ask_notification) }
      end
      expect(user.notifications.count).to eq(1)
    end
  end
end
