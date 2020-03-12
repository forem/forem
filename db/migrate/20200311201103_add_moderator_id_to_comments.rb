class AddModeratorIdToComments < ActiveRecord::Migration[5.2]
  def change
    add_column :comments, :moderator_id, :bigint, references: "users"
  end
end
