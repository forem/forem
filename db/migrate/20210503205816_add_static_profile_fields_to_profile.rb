class AddStaticProfileFieldsToProfile < ActiveRecord::Migration[6.1]
  def change
    add_column :profiles, :summary, :text
    add_column :profiles, :location, :string
    add_column :profiles, :website_url, :string
  end
end
