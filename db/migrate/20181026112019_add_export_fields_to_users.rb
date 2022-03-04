class AddExportFieldsToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :export_requested, :boolean, default: false
    add_column :users, :exported_at, :datetime
  end
end
