class UpdatePollTextResponsesUniqueIndex < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    # Drop the old unique index concurrently
    remove_index :poll_text_responses, [:poll_id, :user_id], 
                 if_exists: true, 
                 algorithm: :concurrently
    
    # Add the new unique index that includes session_start
    add_index :poll_text_responses, [:poll_id, :user_id, :session_start], 
              unique: true,
              name: 'index_poll_text_responses_on_poll_user_session_unique',
              algorithm: :concurrently
  end
end
