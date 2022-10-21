class AddCountsForToDisplayAdEvents < ActiveRecord::Migration[7.0]
  def change
    add_column :display_ad_events, :counts_for, :integer, default: 1, null: false
  end
end
