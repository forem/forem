require "rails_helper"

RSpec.describe Broadcasts::WelcomeNotification::Dispatcher, type: :service do
  let(:user) { create(:user) }

  describe "::call" do
    before do
      allow(Broadcasts::WelcomeNotification::Introduction).to receive(:send)
    end

    it "evokes Introduction" do
      described_class.call(user.id)
      expect(Broadcasts::WelcomeNotification::Introduction).to have_received(:send).with(user)
    end
  end
end
