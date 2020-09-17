class DropUserCounters < ActiveRecord::Migration[6.0]
  def change
    drop_table :user_counters do |t|
      t.references :user, index: { unique: true }
      t.jsonb :data, null: false, default: {}
      t.timestamps null: false

      t.foreign_key :users, on_delete: :cascade
      t.index :data, using: :gin
    end
  end
end
