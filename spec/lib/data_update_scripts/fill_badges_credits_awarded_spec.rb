require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20210322092753_fill_badges_credits_awarded.rb",
)

describe DataUpdateScripts::FillBadgesCreditsAwarded do
  it "updates badges on dev.to" do
    allow(SiteConfig).to receive(:dev_to?).and_return(true)
    badge = create(:badge, credits_awarded: 0)
    expect do
      described_class.new.run
    end.to change { badge.reload.credits_awarded }.from(0).to(5)
  end

  it "doesn't update badges on other forems" do
    allow(SiteConfig).to receive(:dev_to?).and_return(false)
    badge = create(:badge, credits_awarded: 0)
    expect do
      described_class.new.run
    end.not_to change { badge.reload.credits_awarded }
  end
end
