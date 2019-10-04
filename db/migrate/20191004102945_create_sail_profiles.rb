class CreateSailProfiles < ActiveRecord::Migration[5.2]
  def change
    create_table :sail_entries do |t|
      t.string :value, null: false
      t.references :setting, index: true
      t.references :profile, index: true
      t.timestamps
    end

    create_table :sail_profiles do |t|
      t.string :name, null: false
      t.boolean :active, default: false
      t.index ["name"], name: "index_sail_profiles_on_name", unique: true
      t.timestamps
    end

    add_foreign_key(:sail_entries, :sail_settings, column: :setting_id)
    add_foreign_key(:sail_entries, :sail_profiles, column: :profile_id)
  end
end
