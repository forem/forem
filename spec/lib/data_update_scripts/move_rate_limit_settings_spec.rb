require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20210414060839_move_rate_limit_settings.rb",
)

describe DataUpdateScripts::MoveRateLimitSettings do
  it "migrates settings from SiteConfig to Settings::RateLimit" do
    allow(SiteConfig).to receive(:rate_limit_follow_count_daily).and_return(23)
    allow(SiteConfig).to receive(:user_considered_new_days).and_return(42)

    expect do
      described_class.new.run
    end
      .to change(Settings::RateLimit, :follow_count_daily)
      .and change(Settings::RateLimit, :user_considered_new_days)
  end
end
