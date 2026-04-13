require "rails_helper"

RSpec.describe DataFixes::FixTagCounts do
  let(:tag1) { create(:tag) }
  let(:tag2) { create(:tag) }

  it "corrects mismatched tagging counts" do
    create(:article, tags: tag1.name)
    create(:article, tags: tag1.name)
    create(:article, tags: tag2.name)

    Tag.where(id: tag1.id).update_all(taggings_count: 99)
    Tag.where(id: tag2.id).update_all(taggings_count: 0)

    described_class.new.call

    expect(tag1.reload.taggings_count).to eq(2)
    expect(tag2.reload.taggings_count).to eq(1)
  end

  it "sets count to zero for tags with no taggings" do
    Tag.where(id: tag1.id).update_all(taggings_count: 5)

    described_class.new.call

    expect(tag1.reload.taggings_count).to eq(0)
  end

  it "is idempotent" do
    create(:article, tags: tag1.name)

    described_class.new.call
    first_count = tag1.reload.taggings_count

    described_class.new.call
    expect(tag1.reload.taggings_count).to eq(first_count)
  end
end
