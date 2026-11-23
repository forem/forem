require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20261118120000_backfill_core_trust_roles.rb",
)

describe DataUpdateScripts::BackfillCoreTrustRoles do
  before do
    allow(Trackable::Registry).to receive(:active_names).and_return([:any])
    allow(Trackable::DispatchWorker).to receive(:perform_async)
    Settings::General.customerio_cdp_enabled = true
    FeatureFlag.enable(:dev_core_user_sync)
  end

  after { FeatureFlag.remove(:dev_core_user_sync) }

  it "sends the trust roles of every user holding one" do
    moderator = create(:user)
    moderator.add_role(:trusted)
    moderator.add_role(:base_subscriber)
    create(:user).add_role(:warned)

    with_trackable_events { described_class.new.run }

    expect(Trackable::DispatchWorker).to have_received(:perform_async)
      .with(anything, "user_roles_updated", [moderator.id],
            hash_including("dev_roles" => %w[base_subscriber trusted]), anything).once
  end
end
