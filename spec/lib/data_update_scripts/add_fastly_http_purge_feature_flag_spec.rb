require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20210209152726_add_fastly_http_purge_feature_flag.rb",
)

describe DataUpdateScripts::AddFastlyHttpPurgeFeatureFlag do
  after do
    FeatureFlag.remove(:fastly_http_purge)
  end

  it "adds the :fastly_http_purge flag", :aggregate_failures do
    expect do
      described_class.new.run
    end.to change { FeatureFlag.exist?(:fastly_http_purge) }.from(false).to(true)
  end

  it "works if the flag is already available" do
    FeatureFlag.add(:fastly_http_purge)

    expect do
      described_class.new.run
    end.not_to change { FeatureFlag.exist?(:fastly_http_purge) }
  end
end
