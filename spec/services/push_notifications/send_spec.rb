require "rails_helper"

RSpec.describe PushNotifications::Send, type: :service do
  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let(:params) do
    {
      user_ids: [user.id],
      title: "Alert",
      body: "some alert here",
      payload: ""
    }
  end
  let(:many_targets_params) do
    {
      user_ids: [user.id, user2.id],
      title: "Alert 2",
      body: "some other alert",
      payload: ""
    }
  end

  context "with no devices for user" do
    it "does nothing", :aggregate_failures do
      described_class.call(**params)

      sidekiq_assert_no_enqueued_jobs(only: PushNotifications::DeliverWorker)
    end
  end

  context "with devices for one user" do
    before do
      allow(ApplicationConfig).to receive(:[]).with("RPUSH_IOS_PEM").and_return("dGVzdGluZw==")
      allow(ApplicationConfig).to receive(:[]).with("COMMUNITY_NAME").and_return("Forem")
    end

    it "creates a notification and enqueues it" do
      device = create(:device, user: user)
      mocked_objects = mock_rpush(device.consumer_app)

      described_class.call(**params)

      expect(mocked_objects[:rpush_notification]).to have_received(:save!).once

      sidekiq_assert_enqueued_jobs(1, only: PushNotifications::DeliverWorker)
    end

    it "creates a single notification for each of the user's devices when they have multiple" do
      consumer_app = create(:consumer_app)
      devices = create_list(:device, 2, user: user, consumer_app: consumer_app)
      mocked_objects = mock_rpush(consumer_app)

      described_class.call(**params)

      expect(mocked_objects[:rpush_notification]).to have_received(:save!).exactly(devices.size).times

      sidekiq_assert_enqueued_jobs(1, only: PushNotifications::DeliverWorker)
    end
  end

  context "with devices for multiple users" do
    let(:consumer_app) { create(:consumer_app) }

    before do
      allow(ApplicationConfig).to receive(:[]).with("RPUSH_IOS_PEM").and_return("dGVzdGluZw==")
      allow(ApplicationConfig).to receive(:[]).with("COMMUNITY_NAME").and_return("Forem")

      create(:device, user: user, consumer_app: consumer_app)
      create(:device, user: user2, consumer_app: consumer_app)
    end

    it "creates a notification and enqueues it" do
      mocked_objects = mock_rpush(consumer_app)

      described_class.call(**many_targets_params)

      expect(mocked_objects[:rpush_notification]).to have_received(:save!).exactly(2).times

      sidekiq_assert_enqueued_jobs(1, only: PushNotifications::DeliverWorker)
    end

    it "creates a single notification for each of the user's devices when they have multiple" do
      create(:device, user: user)

      mocked_objects = mock_rpush(consumer_app)

      described_class.call(**many_targets_params)

      expect(mocked_objects[:rpush_notification]).to have_received(:save!).exactly(3).times

      sidekiq_assert_enqueued_jobs(1, only: PushNotifications::DeliverWorker)
    end
  end
end
