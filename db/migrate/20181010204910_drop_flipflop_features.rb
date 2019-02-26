class DropFlipflopFeatures < ActiveRecord::Migration[5.1]
  def up
    drop_table :flipflop_features
  end

  def down
    create_table "flipflop_features", force: :cascade do |t|
      t.datetime "created_at", null: false
      t.boolean "enabled", default: false, null: false
      t.string "key", null: false
      t.datetime "updated_at", null: false
    end
  end
end
