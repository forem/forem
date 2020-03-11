class CreateFieldTestEvents < ActiveRecord::Migration[5.2]
  def change
    create_table :field_test_events do |t|
      t.references :field_test_membership
      t.string :name
      t.timestamp :created_at
    end
  end
end
