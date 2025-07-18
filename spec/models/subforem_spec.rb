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
    article1 = create(:article, subforem: subforem, past_published_at: 1.day.ago, score: 10)
    article1 = create(:article, subforem: subforem, past_published_at: 1.week.ago, score: 10)
    article2 = create(:article, subforem: subforem, past_published_at: 3.weeks.ago, score: 5)
    article3 = create(:article, subforem: subforem, past_published_at: 3.months.ago, score: 9)
    article3 = create(:article, subforem: subforem, past_published_at: 8.months.ago, score: 15)  

    subforem.update_scores!

    super_duper_recent = subforem.articles.published.where("published_at > ?", 3.days.ago).sum(:score)
    super_recent       = subforem.articles.published.where("published_at > ?", 2.weeks.ago).sum(:score)
    somewhat_recent    = subforem.articles.published.where("published_at > ?", 6.months.ago).sum(:score)
  
    expected_score        = somewhat_recent + (super_recent * 0.1)
    expected_hotness_score = super_duper_recent + super_recent + (somewhat_recent * 0.1)
  
    expect(subforem.score).to        eq(expected_score.to_i)
    expect(subforem.hotness_score).to eq(expected_hotness_score.to_i)
  end
end
