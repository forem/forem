class DropSailSettings < ActiveRecord::Migration[5.2]
  def up
    drop_table :sail_settings
  end

  def down
    create_table :sail_settings do |t|
      t.string :name, null: false
      t.text :description
      t.string :value, null: false
      t.integer :cast_type, null: false, limit: 1
      t.timestamps
      t.index ["name"], name: "index_settings_on_name", unique: true
    end
  end
end
