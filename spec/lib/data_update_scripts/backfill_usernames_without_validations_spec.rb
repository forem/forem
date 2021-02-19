require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20210219031051_backfill_usernames_without_validations.rb",
)

describe DataUpdateScripts::BackfillUsernamesWithoutValidations do
  it "backfills usernames" do
    user = create(:user)
    user.update_column(:username, nil)
    expect do
      described_class.new.run
    end.to change { user.reload.username }.from(nil).to("user#{user.id}")
  end
end
