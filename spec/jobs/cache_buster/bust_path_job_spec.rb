require "rails_helper"

RSpec.describe CacheBuster::BustPathJob, type: :job do
  include_examples "#enqueues_job", "bust_path", "/"

  describe "#perform_now" do
    it "busts cache" do
      path = Faker::Lorem.sentence
      cache_buster = double
      allow(cache_buster).to receive(:bust)

      described_class.perform_now(path, cache_buster)
      expect(cache_buster).to have_received(:bust).with(path)
    end
  end
end
