class AddSoundcloudUrlToPodcasts < ActiveRecord::Migration[4.2]
  def change
    add_column :podcasts, :soundcloud_url, :string
  end
end
