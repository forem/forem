class AddIpToClicks < ActiveRecord::Migration
  def change
    add_column :ad_clicks, :ip, :string
  end
end
