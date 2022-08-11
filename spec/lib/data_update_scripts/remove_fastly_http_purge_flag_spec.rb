require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20220317151317_remove_fastly_http_purge_flag.rb",
)

describe DataUpdateScripts::RemoveFastlyHttpPurgeFlag do
  it "removes the feature flag if present" do
    FeatureFlag.add(:fastly_http_purge)

    described_class.new.run

    expect(FeatureFlag.exist?(:fastly_http_purge)).to be false
  end

  it "is safe to run twice" do
    # this is the same as "does nothing if flag not present"
    2.times { described_class.new.run }

    expect(FeatureFlag.exist?(:fastly_http_purge)).to be false
  end
end
