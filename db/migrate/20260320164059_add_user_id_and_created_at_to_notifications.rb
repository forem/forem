class AddUserIdAndCreatedAtToNotifications < ActiveRecord::Migration[7.0]
  def up
    # Empty because we decided the index wasn't needed and it was timing out releases.
    # The actual removal of the index (if it managed to build on any community) will happen in a follow-on migration.
  end

  def down
    # Empty
  end
end
