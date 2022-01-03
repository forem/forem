class DropUserOptionalFields < ActiveRecord::Migration[6.0]
  def up
    drop_table :user_optional_fields

    remove_index(:user_optional_fields, [:label, :user_id], unique: true) if
      index_exists?(:user_optional_fields, [:label, :user_id], unique: true)
  end

  def down
    create_table :user_optional_fields do |t|
      t.string :label, null: false
      t.string :value, null: false
      t.references :user, foreign_key: true, null: false

      t.timestamps
    end

    add_index(:user_optional_fields, [:label, :user_id], unique: true) unless
      index_exists?(:user_optional_fields, [:label, :user_id], unique: true)
  end
end
