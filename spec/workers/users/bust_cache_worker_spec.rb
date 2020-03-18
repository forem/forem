require "rails_helper"

RSpec.describe Users::BustCacheWorker, type: :worker do
  describe "#perform" do
    let(:user) { FactoryBot.create(:user) }
    let(:worker) { subject }

    it "busts cache" do
      allow(CacheBuster).to receive(:bust_user)

      worker.perform(user.id)
      expect(CacheBuster).to have_received(:bust_user).with(user)
    end
  end
end
