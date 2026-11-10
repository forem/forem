class AddUnregisteredCreatedAtIndexToUsers < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  # Adds a concurrent partial index on users(created_at DESC) for unregistered (invited) users.
  def change
    add_index :users,
              :created_at,
              order: { created_at: :desc },
              where: "registered = false",
              name: "index_users_on_created_at_where_unregistered",
              algorithm: :concurrently,
              if_not_exists: true
  end
end
