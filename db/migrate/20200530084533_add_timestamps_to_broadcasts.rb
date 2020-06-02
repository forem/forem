class AddTimestampsToBroadcasts < ActiveRecord::Migration[5.2]
  def change
    # NOTE: we need to have nullable timestamps as the table is already
    # populated. Will remove the NULL clause when data is safely backfilled
    add_timestamps(:broadcasts, null: true)
  end
end
