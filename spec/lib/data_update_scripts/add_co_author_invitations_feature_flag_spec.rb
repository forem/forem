require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20261007120001_add_co_author_invitations_feature_flag.rb",
)

describe DataUpdateScripts::AddCoAuthorInvitationsFeatureFlag do
  it "adds the feature flag, disabled", :aggregate_failures do
    described_class.new.run

    expect(FeatureFlag.exist?(:co_author_invitations)).to be(true)
    expect(FeatureFlag.enabled?(:co_author_invitations)).to be(false)
  end
end
