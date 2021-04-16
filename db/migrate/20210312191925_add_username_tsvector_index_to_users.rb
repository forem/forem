class AddUsernameTsvectorIndexToUsers < ActiveRecord::Migration[6.0]
  disable_ddl_transaction!

  INDEX = "to_tsvector('simple'::regconfig, COALESCE((username)::text, ''::text))"
  private_constant :INDEX

  def up
    return if index_exists?(:users, INDEX, name: "index_users_on_username_as_tsvector")

    add_index :users,
              INDEX,
              using: :gin,
              algorithm: :concurrently,
              name: "index_users_on_username_as_tsvector"
  end

  def down
    return unless index_exists?(:users, INDEX, name: "index_users_on_username_as_tsvector")

    remove_index :users,
                 name: "index_users_on_username_as_tsvector",
                 algorithm: :concurrently
  end
end
