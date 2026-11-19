class AddEventIdToPages < ActiveRecord::Migration[8.0]
  def up
    add_column :pages, :event_id, :bigint
    add_foreign_key :pages, :events, on_delete: :cascade, validate: false
  end

  def down
    safety_assured do
      remove_foreign_key :pages, :events
      remove_column :pages, :event_id, :bigint
    end
  end
end
