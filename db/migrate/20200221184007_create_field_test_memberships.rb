class CreateFieldTestMemberships < ActiveRecord::Migration[5.2]
  def change
    create_table :field_test_memberships do |t|
      t.string :participant_type
      t.string :participant_id
      t.string :experiment
      t.string :variant
      t.timestamp :created_at
      t.boolean :converted, default: false
    end

    add_index :field_test_memberships, [:participant_type, :participant_id, :experiment],
      unique: true, name: "index_field_test_memberships_on_participant"
    add_index :field_test_memberships, [:experiment, :created_at]
  end
end
