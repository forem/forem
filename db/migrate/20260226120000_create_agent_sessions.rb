class CreateAgentSessions < ActiveRecord::Migration[7.0]
  def change
    create_table :agent_sessions do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.string :title, null: false
      t.string :tool_name, null: false
      t.text :raw_data
      t.jsonb :normalized_data, default: {}, null: false
      t.jsonb :curated_selections, default: [], null: false
      t.jsonb :session_metadata, default: {}, null: false
      t.boolean :published, default: false, null: false

      t.timestamps
    end

    add_index :agent_sessions, :tool_name
    add_index :agent_sessions, %i[user_id published]
  end
end
