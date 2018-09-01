class AddArticlesExportFieldsToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :articles_export_requested, :boolean, default: false
    add_column :users, :articles_exported_at, :datetime
  end
end
