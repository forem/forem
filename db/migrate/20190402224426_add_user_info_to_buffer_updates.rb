class AddUserInfoToBufferUpdates < ActiveRecord::Migration[5.1]
  def change
    add_column :buffer_updates, :composer_user_id, :integer
    add_column :buffer_updates, :approver_user_id, :integer
    add_column :buffer_updates, :status, :string, default: "pending"
  end
end
