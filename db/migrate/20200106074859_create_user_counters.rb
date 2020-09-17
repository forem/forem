class CreateUserCounters < ActiveRecord::Migration[5.2]
  def change
    create_table :user_counters do |t|
      t.references :user, index: { unique: true }
      t.jsonb :data, null: false, default: {}

      t.timestamps null: false
    end

    add_foreign_key :user_counters, :users, on_delete: :cascade

    add_index :user_counters, :data, using: :gin
  end
end
