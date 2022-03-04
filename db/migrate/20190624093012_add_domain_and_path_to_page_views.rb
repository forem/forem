class AddDomainAndPathToPageViews < ActiveRecord::Migration[5.2]
  def change
    add_column :page_views, :domain, :string
    add_column :page_views, :path, :string
  end
end
