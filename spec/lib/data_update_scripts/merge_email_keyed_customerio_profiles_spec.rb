require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20260923030000_merge_email_keyed_customerio_profiles.rb",
)

describe DataUpdateScripts::MergeEmailKeyedCustomerioProfiles do
  before { allow(ForemInstance).to receive(:customerio_track_enabled?).and_return(true) }

  it "enqueues a merge worker for the id range of users created since the rollout" do
    create(:user, created_at: Time.zone.parse("2026-07-01"))
    user = create(:user, created_at: 1.day.ago)

    described_class.new.run

    expect(Emails::MergeEmailKeyedCustomerioProfilesWorker.jobs.pluck("args"))
      .to eq([[user.id, user.id + described_class::RANGE_SIZE - 1]])
  end

  it "enqueues nothing without Track API credentials" do
    allow(ForemInstance).to receive(:customerio_track_enabled?).and_return(false)
    create(:user, created_at: 1.day.ago)

    described_class.new.run

    expect(Emails::MergeEmailKeyedCustomerioProfilesWorker.jobs).to be_empty
  end
end
