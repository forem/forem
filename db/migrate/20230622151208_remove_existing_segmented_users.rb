class RemoveExistingSegmentedUsers < ActiveRecord::Migration[7.0]
  def up
    SegmentedUser.delete_all
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
