class AddSessionStartToPollTextResponses < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    unless column_exists?(:poll_text_responses, :session_start)
      add_column :poll_text_responses, :session_start, :integer, default: 0, null: false
    end
    
    unless index_exists?(:poll_text_responses, [:user_id, :poll_id, :session_start], name: 'index_poll_text_responses_on_user_poll_session')
      add_index :poll_text_responses, [:user_id, :poll_id, :session_start], 
                name: 'index_poll_text_responses_on_user_poll_session', 
                algorithm: :concurrently
    end
  end
end
