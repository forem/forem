class AddIngestTokenToAgentSessions < ActiveRecord::Migration[7.1]
  def change
    add_column :agent_sessions, :ingest_token, :string
    add_index :agent_sessions, :ingest_token, unique: true, where: "ingest_token IS NOT NULL"
  end
end
