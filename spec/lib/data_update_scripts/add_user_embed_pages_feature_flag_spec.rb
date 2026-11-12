require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20261112120000_add_user_embed_pages_feature_flag.rb",
)

describe DataUpdateScripts::AddUserEmbedPagesFeatureFlag do
  it "adds the feature flag, disabled", :aggregate_failures do
    described_class.new.run

    expect(FeatureFlag.exist?(:user_embed_pages)).to be(true)
    expect(FeatureFlag.enabled?(:user_embed_pages)).to be(false)
  end
end
