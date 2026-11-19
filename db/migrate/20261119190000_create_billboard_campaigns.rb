class CreateBillboardCampaigns < ActiveRecord::Migration[8.0]
  def change
    create_table :billboard_campaigns do |t|
      t.string :name, null: false
      t.references :organization, foreign_key: { on_delete: :nullify }
      t.datetime :expires_at
      t.integer :max_impressions_count, null: false, default: 0
      t.integer :max_clicks_count, null: false, default: 0

      t.timestamps
    end
  end
end
