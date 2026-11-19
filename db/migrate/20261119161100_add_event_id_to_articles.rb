class AddEventIdToArticles < ActiveRecord::Migration[8.0]
  def up
    add_column :articles, :event_id, :bigint
    add_foreign_key :articles, :events, on_delete: :nullify, validate: false
  end

  def down
    safety_assured do
      remove_foreign_key :articles, :events
      remove_column :articles, :event_id, :bigint
    end
  end
end
