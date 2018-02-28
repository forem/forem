class CreateAdClicks < ActiveRecord::Migration
  def change
    create_table :ad_clicks do |t|
      t.integer :article_id
      t.integer :advertisement_id
      t.timestamps null: false
    end
  end
end
