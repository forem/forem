require 'rails_helper'

RSpec.describe Subforem, type: :model do
  it "calls subforem_default_idods after save" do
    subforem = create(:subforem)
    expect(Rails.cache).to receive(:delete).with('settings/general')
    expect(Rails.cache).to receive(:delete).with("settings/general-#{subforem.id}")
    expect(Rails.cache).to receive(:delete).with('cached_domains')
    expect(Rails.cache).to receive(:delete).with('subforem_id_to_domain_hash')
    expect(Rails.cache).to receive(:delete).with('subforem_postable_array')
    expect(Rails.cache).to receive(:delete).with('subforem_discoverable_ids')
    expect(Rails.cache).to receive(:delete).with('subforem_root_id')
    expect(Rails.cache).to receive(:delete).with('subforem_default_domain')
    expect(Rails.cache).to receive(:delete).with('subforem_root_domain')
    expect(Rails.cache).to receive(:delete).with('subforem_all_domains')
    expect(Rails.cache).to receive(:delete).with('subforem_default_id')
    expect(Rails.cache).to receive(:delete).with("subforem_id_by_domain_#{subforem.domain}")
    subforem.save
  end

  it "downcases domain before validation" do
    subforem = build(:subforem, domain: "UPPERCASE.com")
    subforem.valid?
    expect(subforem.domain).to eq("uppercase.com")
  end

  it "calculates score and hotness_score correctly" do
    subforem = create(:subforem)
    article1 = create(:article, subforem: subforem, published_at: 1.month.ago, score: 10)
    article2 = create(:article, subforem: subforem, published_at: 3.weeks.ago, hotness_score: 5)

    subforem.update_scores!

    expect(subforem.score).to eq(10)
    expect(subforem.hotness_score).to eq(5 + (10 * 0.1)) # hotness_score includes a fraction of the score
  end
end
