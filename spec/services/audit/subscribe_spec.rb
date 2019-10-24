require "rails_helper"

RSpec.describe Audit::Subscribe, type: :service do
  let(:notifications) { ActiveSupport::Notifications }
  let(:listeners) { %i[moderator visitor] }
  let(:listener_suffix) { Audit::Helper::NOTIFICATION_SUFFIX }

  before do
    listeners.each do |listener|
      allow(notifications).to receive(:subscribe).with([listener, listener_suffix].join)
    end
  end

  it "can subscribe to custom listeners" do
    described_class.listen(*listeners)

    listeners.each do |listener|
      expect(notifications).to have_received(:subscribe).with([listener, listener_suffix].join)
    end
  end
end
