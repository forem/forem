class AddEventIdToEmails < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    add_column :emails, :event_id, :bigint
    add_index :emails, :event_id, algorithm: :concurrently
  end
end
