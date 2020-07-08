class AddPathToCollections < ActiveRecord::Migration[6.0]
  def change
    add_column :collections, :path, :string
  end
end
