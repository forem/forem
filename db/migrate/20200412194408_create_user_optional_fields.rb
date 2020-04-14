class CreateUserOptionalFields < ActiveRecord::Migration[5.2]
  def change
    create_table :user_optional_fields do |t|
      t.string :label
      t.string :value
      t.references :user, foreign_key: true

      t.timestamps
    end

    add_index :user_optional_fields, [:label, :user_id], unique: true
  end
end
