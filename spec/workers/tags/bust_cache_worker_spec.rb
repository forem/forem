require "rails_helper"

RSpec.describe Tags::BustCacheWorker, type: :worker do
  let(:worker) { subject }

  # Passing in random tag
  include_examples "#enqueues_on_correct_queue", "high_priority", ["php"]

  describe "#perform_now" do
    it "busts cache" do
      tag = create(:tag)
      allow(EdgeCache::BustTag).to receive(:call).with(tag)

      worker.perform(tag.name)

      expect(EdgeCache::BustTag).to have_received(:call).with(tag)
    end

    it "doesn't call the cache buster if the tag does not exist" do
      allow(EdgeCache::BustTag).to receive(:call)
      tag_name = "definitelyatagthatdoesnotexist"

      worker.perform(tag_name)

      expect(EdgeCache::BustTag).not_to have_received(:call)
    end
  end
end
