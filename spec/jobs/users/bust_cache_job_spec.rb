require "rails_helper"

RSpec.describe Users::BustCacheJob, type: :job do
  include_examples "#enqueues_job", "users_bust_cache", [1, 2]

  describe "#perform_now" do
    let(:user) { FactoryBot.create(:user) }

    it "busts cache" do
      path = user.path

      cache_buster = double
      allow(cache_buster).to receive(:bust)

      described_class.perform_now(user.id, cache_buster) do
        expect(cache_buster).to have_received(:bust).with(path)
        expect(cache_buster).to have_received(:bust).with("/feed#{path}")
      end
    end
  end
end
