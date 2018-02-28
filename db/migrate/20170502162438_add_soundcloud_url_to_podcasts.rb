class AddSoundcloudUrlToPodcasts < ActiveRecord::Migration
  def change
    add_column :podcasts, :soundcloud_url, :string
  end
end
