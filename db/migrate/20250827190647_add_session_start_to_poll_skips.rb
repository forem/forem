class AddSessionStartToPollSkips < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_column :poll_skips, :session_start, :integer, default: 0, null: false
    add_index :poll_skips, [:user_id, :poll_id, :session_start], 
              name: 'index_poll_skips_on_user_poll_session', 
              algorithm: :concurrently
  end
end
