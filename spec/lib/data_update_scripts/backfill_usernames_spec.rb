require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20210218041143_backfill_usernames.rb",
)

describe DataUpdateScripts::BackfillUsernames do
  it " " do
    user = create(:user)
    user.update_column(:username, nil)
    expect do
      described_class.new.run
    end.to change { user.reload.username }.from(nil).to("user#{user.id}")
  end
end
