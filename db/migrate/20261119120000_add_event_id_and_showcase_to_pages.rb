class AddEventIdAndShowcaseToPages < ActiveRecord::Migration[8.0]
  def up
    change_table :pages, bulk: true do |t|
      t.bigint :event_id
      t.boolean :showcase, default: false, null: false
    end
    add_foreign_key :pages, :events, on_delete: :cascade, validate: false
  end

  def down
    safety_assured do
      remove_foreign_key :pages, :events
      change_table :pages, bulk: true do |t|
        t.remove :showcase
        t.remove :event_id
      end
    end
  end
end
