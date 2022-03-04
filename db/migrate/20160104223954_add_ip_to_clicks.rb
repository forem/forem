class AddIpToClicks < ActiveRecord::Migration[4.2]
  def change
    add_column :ad_clicks, :ip, :string
  end
end
