class AddUniqueWebsiteUrlBooleanToPodcasts < ActiveRecord::Migration[5.1]
  def change
    add_column :podcasts, :unique_website_url?, :boolean, default: true
  end
end
