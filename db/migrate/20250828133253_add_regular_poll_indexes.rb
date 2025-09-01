class AddRegularPollIndexes < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    # Add indexes for regular polls (non-survey polls) that don't include session_start
    # These are partial indexes that only apply when session_start = 0 (default for regular polls)
    add_index :poll_votes, [:poll_id, :user_id], 
              where: "session_start = 0",
              name: 'index_poll_votes_on_poll_user_regular',
              algorithm: :concurrently
              
    add_index :poll_votes, [:poll_option_id, :user_id], 
              where: "session_start = 0",
              name: 'index_poll_votes_on_poll_option_user_regular',
              algorithm: :concurrently
  end
end
