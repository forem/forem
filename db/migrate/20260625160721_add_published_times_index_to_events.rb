class AddPublishedTimesIndexToEvents < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def up
    unless index_exists?(:events, [:start_time, :end_time], name: "index_events_on_start_time_and_end_time_published")
      add_index :events, [:start_time, :end_time],
                name: "index_events_on_start_time_and_end_time_published",
                where: "published = true",
                algorithm: :concurrently
    end
  end

  def down
    if index_exists?(:events, [:start_time, :end_time], name: "index_events_on_start_time_and_end_time_published")
      remove_index :events, name: "index_events_on_start_time_and_end_time_published", algorithm: :concurrently
    end
  end
end
