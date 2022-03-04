class AddReactableTypeReactableIdIndexToReactions < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_index :reactions, %i[reactable_id reactable_type], algorithm: :concurrently
  end
end
