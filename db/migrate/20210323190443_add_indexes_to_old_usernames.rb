class AddIndexesToOldUsernames < ActiveRecord::Migration[6.0]
  disable_ddl_transaction!

  def change
    # Used in StoriesController#show and #index
    add_index :users, :old_username, algorithm: :concurrently
  end
end
