require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20210114174504_update_user_update_rate_limit_default.rb",
)

describe DataUpdateScripts::UpdateUserUpdateRateLimitDefault do
  it "updates rate limit if 5 or less" do
    described_class.new.run
    expect(SiteConfig.rate_limit_user_update).to eq(15)
  end

  it "does NOT update the rate limit if greater than 5" do
    allow(SiteConfig).to receive(:rate_limit_user_update).and_return(10)
    described_class.new.run
    expect(SiteConfig.rate_limit_user_update).to eq(10)
  end
end
