class AddIndexesToEventMemberships < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def up
    safety_assured do
      execute "SET statement_timeout = 0;"
      add_index :event_memberships, %i[parent_event_id child_event_id],
                unique: true,
                name: "index_event_memberships_on_parent_and_child",
                algorithm: :concurrently,
                if_not_exists: true
      add_index :event_memberships, %i[parent_event_id position id],
                name: "index_event_memberships_on_parent_position_id",
                algorithm: :concurrently,
                if_not_exists: true
      add_index :event_memberships, %i[child_event_id parent_event_id],
                name: "index_event_memberships_on_child_and_parent",
                algorithm: :concurrently,
                if_not_exists: true
    end
  end

  def down
    safety_assured do
      execute "SET statement_timeout = 0;"
      remove_index :event_memberships,
                   name: "index_event_memberships_on_parent_and_child",
                   algorithm: :concurrently,
                   if_exists: true
      remove_index :event_memberships,
                   name: "index_event_memberships_on_parent_position_id",
                   algorithm: :concurrently,
                   if_exists: true
      remove_index :event_memberships,
                   name: "index_event_memberships_on_child_and_parent",
                   algorithm: :concurrently,
                   if_exists: true
    end
  end
end
