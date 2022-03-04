class CreateProfileFields < ActiveRecord::Migration[6.0]
  def change
    create_table :profile_fields do |t|
      enable_extension("citext")

      t.citext :label, null: false, index: { unique: true }
      t.integer :input_type, null: false, default: 0
      t.string :placeholder_text
      t.boolean :active, null: false, default: true

      t.timestamps
    end
  end
end
