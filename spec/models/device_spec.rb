require "rails_helper"

RSpec.describe Device, type: :model do
  let(:device) { create(:device) }
  let(:user) { create(:user) }

  describe "validations" do
    subject { device }

    describe "builtin validations" do
      it { is_expected.to belong_to(:consumer_app) }
      it { is_expected.to belong_to(:user) }

      it { is_expected.to validate_presence_of(:token) }
      it { is_expected.to validate_uniqueness_of(:token).scoped_to(%i[user_id platform consumer_app_id]) }
    end
  end

  describe "#create_notification" do
    let(:data_hash) { { "alert" => "Hello World" } }

    context "when iOS device" do
      let(:consumer_app_ios) { create(:consumer_app, platform: :ios) }

      it "creates an Apns2 notification" do
        mocked_objects = mock_rpush(consumer_app_ios)

        device = create(:device, user: user, platform: "iOS")
        device.create_notification("Subtitle", "Body", data_hash)
        expect(mocked_objects[:rpush_notification].data[:aps][:alert][:title]).to eq(Settings::Community.community_name)
        expect(mocked_objects[:rpush_notification].data[:aps][:alert][:subtitle]).to eq("Subtitle")
        expect(mocked_objects[:rpush_notification].data[:aps][:alert][:body]).to eq("Body")
        expect(mocked_objects[:rpush_notification].data[:aps][:"thread-id"]).to eq(Settings::Community.community_name)
        expect(mocked_objects[:rpush_notification].data[:aps][:sound]).to eq("default")
        expect(mocked_objects[:rpush_notification].data[:data]).to eq(data_hash)
      end
    end
  end
end
