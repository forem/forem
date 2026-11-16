class AddIndexToPagesUserId < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def up
    safety_assured do
      execute "SET statement_timeout = 0;"
      remove_index :pages, name: "index_pages_on_user_id", if_exists: true, algorithm: :concurrently
      add_index :pages, :user_id, algorithm: :concurrently
    end
  end

  def down
    safety_assured do
      execute "SET statement_timeout = 0;"
      remove_index :pages, name: "index_pages_on_user_id", if_exists: true, algorithm: :concurrently
    end
  end
end
