class CreateDisplayAds < ActiveRecord::Migration[5.1]
  def change
    create_table :display_ads do |t|
      t.integer :organization_id
      t.string :placement_area
      t.text :body_markdown
      t.text :processed_html
      t.float   :cost_per_impression, default: 0
      t.float   :cost_per_click, default: 0
      t.integer :impressions_count, default: 0
      t.integer :clicks_count, default: 0
      t.boolean :published, default: false
      t.boolean :approved, default: false
      t.timestamps
    end
  end
end
