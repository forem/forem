class AddIndexOnElevatedUpcomingEvents < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_index :events, [:end_time, :start_time],
              where: "published = TRUE AND elevated = TRUE",
              name: "index_events_on_end_time_and_start_time_elevated_published",
              algorithm: :concurrently
  end
end
