class AddNewFieldsToBillboardEvents < ActiveRecord::Migration[7.0]
  def change
    add_column :display_ad_events, :article_id, :integer
    add_column :display_ad_events, :geolocation, :string
  end
end
