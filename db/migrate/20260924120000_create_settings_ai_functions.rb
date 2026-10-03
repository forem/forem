class CreateSettingsAiFunctions < ActiveRecord::Migration[8.0]
  def change
    # Indexes are created with the table itself: it is new and empty, so there is nothing to lock.
    create_table :settings_ai_functions do |t|
      t.string :var, null: false
      t.text :value
      t.bigint :subforem_id

      t.timestamps
    end

    add_index :settings_ai_functions, :subforem_id
    add_index :settings_ai_functions, %i[var subforem_id], unique: true
  end
end
