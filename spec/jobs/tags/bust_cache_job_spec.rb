require "rails_helper"

RSpec.describe Tags::BustCacheJob do
  before do
    allow(CacheBuster).to receive(:bust_tag)
  end

  include_examples "#enqueues_job", "tags_bust_cache", "php"

  describe "#perform_now" do
    it "busts cache" do
      tag = create(:tag)

      described_class.perform_now(tag.name)

      expect(CacheBuster).to have_received(:bust_tag).with(tag)
    end

    it "doesn't call the cache buster if the tag does not exist" do
      tag_name = "definitelyatagthatdoesnotexist"

      described_class.perform_now(tag_name)

      expect(CacheBuster).not_to have_received(:bust_tag)
    end
  end
end
