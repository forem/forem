require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20260223130701_recount_taggings.rb",
)

RSpec.describe DataUpdateScripts::RecountTaggings do
  let(:tag1) { create(:tag) }
  let(:tag2) { create(:tag) }

  it "fixes mismatched tagging counts" do
    create(:article, tags: tag1.name)
    create(:article, tags: tag1.name)
    create(:article, tags: tag2.name)

    # Manually break the counter cache to simulate incorrect counters
    Tag.where(id: tag1.id).update_all(taggings_count: 99)
    Tag.where(id: tag2.id).update_all(taggings_count: 0)

    described_class.new.run

    expect(tag1.reload.taggings_count).to eq(2)
    expect(tag2.reload.taggings_count).to eq(1)
  end

  it "handles tags with no taggings" do
    Tag.where(id: tag1.id).update_all(taggings_count: 5)

    described_class.new.run

    expect(tag1.reload.taggings_count).to eq(0)
  end

  it "is idempotent" do
    create(:article, tags: tag1.name)

    described_class.new.run
    first_count = tag1.reload.taggings_count

    described_class.new.run
    second_count = tag1.reload.taggings_count

    expect(first_count).to eq(second_count)
  end
end
