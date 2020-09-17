class AddBannerStyleToBroadcasts < ActiveRecord::Migration[6.0]
  def change
    add_column :broadcasts, :banner_style, :string
  end
end
