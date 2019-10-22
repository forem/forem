class ChangeMastodonUrlToFediverseUrl < ActiveRecord::Migration[5.2]
  def change
    rename_column :users, :mastodon_url, :fediverse_url
  end
end
