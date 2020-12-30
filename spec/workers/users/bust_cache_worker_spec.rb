require "rails_helper"

RSpec.describe Users::BustCacheWorker, type: :worker do
  describe "#perform" do
    let(:user) { FactoryBot.create(:user) }
    let(:worker) { subject }

    it "busts cache" do
      allow(EdgeCache::BustUser).to receive(:call).with(user)

      worker.perform(user.id)
      expect(EdgeCache::BustUser).to have_received(:call).with(user)
    end
  end
end
