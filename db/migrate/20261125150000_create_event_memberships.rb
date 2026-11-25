class CreateEventMemberships < ActiveRecord::Migration[8.0]
  def change
    create_table :event_memberships do |t|
      t.bigint :parent_event_id, null: false
      t.bigint :child_event_id, null: false
      t.integer :position, default: 0, null: false
      t.string :role, limit: 64
      t.boolean :featured, default: false, null: false

      t.timestamps
    end

    add_check_constraint :event_memberships,
                         "parent_event_id <> child_event_id",
                         name: "event_memberships_no_self_reference"
    add_foreign_key :event_memberships, :events, column: :parent_event_id, on_delete: :cascade, validate: false
    add_foreign_key :event_memberships, :events, column: :child_event_id, on_delete: :cascade, validate: false
  end
end
