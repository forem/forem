class AddUniqueIndexToReactionsUserId < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_index(
      :reactions,
      %i[user_id reactable_id reactable_type category],
      unique: true,
      algorithm: :concurrently,
      name: :index_reactions_on_user_id_reactable_id_reactable_type_category
    )
  end
end
