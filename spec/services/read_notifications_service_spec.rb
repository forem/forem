require "rails_helper"

RSpec.describe ReadNotificationsService do
  let(:user) { create(:user) }
  let(:mock) { instance_double(NotificationCounter) }

  before do
    allow(NotificationCounter).to receive(:new) { mock }
    allow(mock).to receive(:set_to_zero).and_return(true)
  end

  it "returns read when #mark_as_read is called" do
    expect(described_class.new(user).mark_as_read).to eq("read")
  end
end
