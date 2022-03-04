class CreateDisplayAdEvents < ActiveRecord::Migration[5.2]
  def change
    create_table :display_ad_events do |t|
      t.integer     :display_ad_id
      t.integer     :user_id
      t.string      :category
      t.string      :context_type
      t.bigint      :context_id
      t.integer     :counts_for, default: 1

      t.timestamps
    end
    add_index("display_ad_events", "display_ad_id")
    add_index("display_ad_events", "user_id")
  end
end
