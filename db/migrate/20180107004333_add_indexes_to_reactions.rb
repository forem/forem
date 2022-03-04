class AddIndexesToReactions < ActiveRecord::Migration[5.1]
  def change
    add_index :reactions, :reactable_id
    add_index :reactions, :category
    add_index :reactions, :reactable_type
  end
end
