class AddIndexToPagesEventId < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def up
    safety_assured do
      execute "SET statement_timeout = 0;"
      remove_index :pages, name: "index_pages_on_event_id", if_exists: true, algorithm: :concurrently
      add_index :pages, :event_id, algorithm: :concurrently
      remove_index :pages, name: "index_pages_on_event_id_showcase_unique", if_exists: true, algorithm: :concurrently
      add_index :pages, :event_id,
                unique: true,
                where: "event_id IS NOT NULL AND showcase = true",
                name: "index_pages_on_event_id_showcase_unique",
                algorithm: :concurrently
    end
  end

  def down
    safety_assured do
      execute "SET statement_timeout = 0;"
      remove_index :pages, name: "index_pages_on_event_id_showcase_unique", if_exists: true, algorithm: :concurrently
      remove_index :pages, name: "index_pages_on_event_id", if_exists: true, algorithm: :concurrently
    end
  end
end
