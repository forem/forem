class AddSecondsVisibleToDisplayAdEvents < ActiveRecord::Migration[7.0]
  def change
    unless column_exists?(:display_ad_events, :seconds_visible)
      add_column :display_ad_events, :seconds_visible, :integer, default: 10, null: false
    end
  end
end
