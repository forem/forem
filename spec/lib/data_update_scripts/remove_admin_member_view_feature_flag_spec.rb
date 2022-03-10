require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20220309194124_remove_admin_member_view_feature_flag.rb",
)

describe DataUpdateScripts::RemoveAdminMemberViewFeatureFlag do
  it "disables the :admin_member_view feature flag" do
    FeatureFlag.enable(:admin_member_view)

    described_class.new.run

    expect(FeatureFlag.enabled?(:admin_member_view)).to be(false)
  end

  it "removes the :admin_member_view feature flag" do
    FeatureFlag.enable(:admin_member_view)

    described_class.new.run

    expect(FeatureFlag.exist?(:admin_member_view)).to be(false)
  end

  it "works if the flag is not available" do
    described_class.new.run

    expect(FeatureFlag.exist?(:admin_member_view)).to be(false)
  end
end
