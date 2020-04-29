class CreateUserOptionalFields < ActiveRecord::Migration[5.2]
  def change
    create_table :user_optional_fields do |t|
      t.string :label, null: false
      t.string :value, null: false
      t.references :user, foreign_key: true, null: false

      t.timestamps
    end

    add_index :user_optional_fields, [:label, :user_id], unique: true
  end
end
