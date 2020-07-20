class RemoveBannerStyleFromBroadcasts < ActiveRecord::Migration[6.0]
  def change
    safety_assured { remove_column :broadcasts, :banner_style, :string }
  end
end
