class AddDomainAndPathToPageViews < ActiveRecord::Migration[5.2]
  def change
    add_column :page_views, :domain, :string, null: false, default: ""
    add_index :page_views, :domain
    add_column :page_views, :path, :string, null: false, default: ""
  end
end
