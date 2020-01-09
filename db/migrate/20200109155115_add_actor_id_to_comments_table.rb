class AddActorIdToCommentsTable < ActiveRecord::Migration[5.2]
  def change
    add_column :comments, :actor_id, :integer
  end
end
