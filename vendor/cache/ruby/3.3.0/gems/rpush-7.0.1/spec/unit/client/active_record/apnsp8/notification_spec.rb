require "unit_spec_helper"

describe Rpush::Client::ActiveRecord::Apnsp8::Notification do
  subject(:notification) { described_class.new }

  it_behaves_like 'Rpush::Client::Apns::Notification'
  it_behaves_like 'Rpush::Client::ActiveRecord::Notification'

  it "should validate the length of the binary conversion of the notification", :aggregate_failures do
    notification = described_class.new
    notification.app = Rpush::Apnsp8::App.create(apn_key: "1",
                                                 apn_key_id: "2",
                                                 name: 'test',
                                                 environment: 'development',
                                                 team_id: "3",
                                                 bundle_id: "4")
    notification.device_token = "a" * 108
    notification.alert = ""

    notification.alert << "a" until notification.payload.bytesize == 4096
    expect(notification.valid?).to be_truthy
    expect(notification.errors[:base]).to be_empty

    notification.alert << "a"
    expect(notification.valid?).to be_falsey
    expect(notification.errors[:base].include?("APN notification cannot be larger than 4096 bytes. Try condensing your alert and device attributes.")).to be_truthy
  end
end if active_record?
