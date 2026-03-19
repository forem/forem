require "rails_helper"

RSpec.describe DataFixes::VerifyTagCounts do
  let(:tag1) { create(:tag) }
  let(:tag2) { create(:tag) }

  it "returns total and mismatched counts" do
    create(:article, tags: tag1.name)
    create(:article, tags: tag2.name)

    Tag.where(id: tag1.id).update_all(taggings_count: 99)

    result = described_class.new.call

    expect(result[:mismatched]).to eq(1)
    expect(result[:total]).to be >= 2
  end

  it "reports zero mismatches when all counts are accurate" do
    create(:article, tags: tag1.name)

    result = described_class.new.call

    expect(result[:mismatched]).to eq(0)
  end

  it "does not modify any data" do
    create(:article, tags: tag1.name)
    Tag.where(id: tag1.id).update_all(taggings_count: 99)

    described_class.new.call

    expect(tag1.reload.taggings_count).to eq(99)
  end
end
