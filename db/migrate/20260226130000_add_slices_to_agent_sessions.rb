class AddSlicesToAgentSessions < ActiveRecord::Migration[7.0]
  def change
    add_column :agent_sessions, :slices, :jsonb, default: [], null: false
  end
end
