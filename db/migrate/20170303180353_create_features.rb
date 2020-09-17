class CreateFeatures < ActiveRecord::Migration[4.2]
  def change
    create_table :features do |t|
    t.string :key, null: false
    t.boolean :enabled, null: false, default: false
    t.timestamps null: false
    end
  end
end
