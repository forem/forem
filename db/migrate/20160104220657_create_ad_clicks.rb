class CreateAdClicks < ActiveRecord::Migration[4.2]
  def change
    create_table :ad_clicks do |t|
      t.integer :article_id
      t.integer :advertisement_id
      t.timestamps null: false
    end
  end
end
