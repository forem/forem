require "rails_helper"

RSpec.describe Tags::BustCacheWorker, type: :worker do
  let(:worker) { subject }

  before { allow(CacheBuster).to receive(:bust_tag) }

  # Passing in random tag
  include_examples "#enqueues_on_correct_queue", "high_priority", ["php"]

  describe "#perform_now" do
    it "busts cache" do
      tag = create(:tag)

      worker.perform(tag.name)

      expect(CacheBuster).to have_received(:bust_tag).with(tag)
    end

    it "doesn't call the cache buster if the tag does not exist" do
      tag_name = "definitelyatagthatdoesnotexist"

      worker.perform(tag_name)

      expect(CacheBuster).not_to have_received(:bust_tag)
    end
  end
end
