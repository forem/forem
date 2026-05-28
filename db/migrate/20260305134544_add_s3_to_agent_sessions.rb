class AddS3ToAgentSessions < ActiveRecord::Migration[7.0]
  def change
    add_column :agent_sessions, :s3_key, :string
    add_column :agent_sessions, :curated_data, :jsonb, default: {}, null: false
  end
end
