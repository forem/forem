class AddSessionStartToPollVotes < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_column :poll_votes, :session_start, :integer, default: 0, null: false
    add_index :poll_votes, [:user_id, :poll_id, :session_start], 
              name: 'index_poll_votes_on_user_poll_session', 
              algorithm: :concurrently
  end
end
