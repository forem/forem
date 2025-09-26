class UpdatePollVotesUniqueIndex < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    # Drop the old unique index on poll_option_id and user_id
    remove_index :poll_votes, [:poll_option_id, :user_id], 
                 if_exists: true, 
                 algorithm: :concurrently
    
    # Add the new unique index that includes session_start
    add_index :poll_votes, [:poll_option_id, :user_id, :session_start], 
              unique: true,
              name: 'index_poll_votes_on_poll_option_user_session_unique',
              algorithm: :concurrently
  end
end
