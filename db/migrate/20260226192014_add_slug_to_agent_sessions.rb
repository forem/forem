class AddSlugToAgentSessions < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_column :agent_sessions, :slug, :string, if_not_exists: true
    add_index :agent_sessions, :slug, unique: true, algorithm: :concurrently, if_not_exists: true
  end
end
