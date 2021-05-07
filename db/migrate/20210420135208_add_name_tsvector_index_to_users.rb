class AddNameTsvectorIndexToUsers < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def up
    add_index(
      :users,
      "to_tsvector('simple'::regconfig, COALESCE((name)::text, ''::text))",
      using: :gin,
      name: :index_users_on_name_as_tsvector,
      algorithm: :concurrently
    )
  end

  def down
    remove_index :users, name: :index_users_on_name_as_tsvector, algorithm: :concurrently, if_exists: true
  end
end
