class RemoveLegacyColumnsFromAgentSessions < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      remove_column :agent_sessions, :raw_data, :text
      remove_column :agent_sessions, :normalized_data, :jsonb, default: {}, null: false
      remove_column :agent_sessions, :curated_selections, :jsonb, default: [], null: false
    end
  end
end
