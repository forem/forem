class AddBrinIndexToFieldTestEvents < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_index :field_test_events, 
              :created_at, 
              using: :brin, 
              algorithm: :concurrently,
              name: "index_field_test_events_on_created_at_brin"
  end
end
