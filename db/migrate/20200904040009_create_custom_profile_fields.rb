class CreateCustomProfileFields < ActiveRecord::Migration[6.0]
  def change
    safety_assured do
      create_table :custom_profile_fields do |t|
        t.references :profile, null: false

        t.string "attribute_name", null: false
        t.string "description"
        t.citext "label", null: false

        t.timestamps
      end

      add_foreign_key :custom_profile_fields, :profiles, on_delete: :cascade
      add_index :custom_profile_fields, [:label, :profile_id], unique: true
    end
  end
end
