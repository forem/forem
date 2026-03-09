class AddSidebarCountersToUsers < ActiveRecord::Migration[7.0]
  def up
    add_column :users, :agent_sessions_count, :integer, default: 0, null: false

    safety_assured do
      execute <<-SQL.squish
        UPDATE users
        SET agent_sessions_count = (
          SELECT count(*)
          FROM agent_sessions
          WHERE agent_sessions.user_id = users.id
        )
        WHERE EXISTS (
          SELECT 1
          FROM agent_sessions
          WHERE agent_sessions.user_id = users.id
        )
      SQL
    end
  end

  def down
    safety_assured do
      remove_column :users, :agent_sessions_count
    end
  end
end
