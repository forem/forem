require "rails_helper"

RSpec.describe PushNotifications::Send, type: :service do
  let(:user) { create(:user) }
  let(:params) do
    {
      user: user,
      title: "Alert",
      body: "some alert here",
      payload: ""
    }
  end

  context "with feature flag set to false/off" do
    before { allow(FeatureFlag).to receive(:enabled?).with(:mobile_notifications).and_return(false) }

    it "does nothing if the feature flag is disabled" do
      expect { described_class.call(params) }
        .not_to change { Rpush::Client::Redis::Notification.all.count }
    end
  end

  context "with no devices for user" do
    before do
      allow(FeatureFlag).to receive(:enabled?).with(:mobile_notifications).and_return(true)
      user.devices.delete
    end

    it "does nothing", :aggregate_failures do
      expect(user.devices.count).to eq(0)
      expect { described_class.call(params) }
        .not_to change { Rpush::Client::Redis::Notification.all.count }
    end
  end

  context "with devices for user" do
    before do
      allow(FeatureFlag).to receive(:enabled?).with(:mobile_notifications).and_return(true)
      allow(ApplicationConfig).to receive(:[]).with("RPUSH_IOS_PEM").and_return("dGVzdGluZw==")
      allow(ApplicationConfig).to receive(:[]).with("COMMUNITY_NAME").and_return("Forem")
      create(:device, user: user)
    end

    it "creates a notification and enqueues it" do
      expect { described_class.call(params) }
        .to change { Rpush::Client::Redis::Notification.all.count }.by(1)
        .and change(PushNotifications::DeliverWorker.jobs, :size).by(1)
    end

    it "creates a single notification for each of the user's devices when they have multiple" do
      create(:device, user: user)

      expect { described_class.call(params) }
        .to change { Rpush::Client::Redis::Notification.all.count }.by(2)
        .and change(PushNotifications::DeliverWorker.jobs, :size).by(1)
    end
  end
end
