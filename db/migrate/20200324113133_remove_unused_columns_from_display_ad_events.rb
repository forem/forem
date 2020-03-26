class RemoveUnusedColumnsFromDisplayAdEvents < ActiveRecord::Migration[5.2]
  def change
    safety_assured do
      remove_column :display_ad_events, :context_id, :bigint
      remove_column :display_ad_events, :counts_for, :integer, default: 1
    end
  end
end
