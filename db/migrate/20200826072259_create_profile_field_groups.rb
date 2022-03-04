class CreateProfileFieldGroups < ActiveRecord::Migration[6.0]
  def change
    create_table :profile_field_groups do |t|
      t.string :name, null: false
      t.string :description

      t.timestamps
    end

    add_index :profile_field_groups, :name, unique: true
  end
end
